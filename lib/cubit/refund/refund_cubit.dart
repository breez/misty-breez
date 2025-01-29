import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

export 'refund_state.dart';

final Logger _logger = Logger('RefundCubit');

class RefundCubit extends Cubit<RefundState> {
  StreamSubscription<PaymentEvent>? _paymentEventSubscription;

  final BreezSDKLiquid _breezSdkLiquid;

  RefundCubit(this._breezSdkLiquid) : super(RefundState.initial()) {
    _initializeRefundCubit();
    _listenRefundEvents();
  }

  void _initializeRefundCubit() {
    _breezSdkLiquid.getInfoResponseStream.first.then((_) => listRefundables());
  }

  void listRefundables() async {
    try {
      _logger.info('Refreshing refundables');
      final List<RefundableSwap> refundables = await _breezSdkLiquid.instance!.listRefundables();
      _logger.info('Refundables: $refundables');
      emit(state.copyWith(refundables: refundables));
    } catch (e) {
      _logger.severe('Failed to list refundables', e);
      emit(state.copyWith());
    }
  }

  void _listenRefundEvents() {
    _logger.info('Listening to Refund events');
    _paymentEventSubscription = _breezSdkLiquid.paymentEventStream.listen(
      (PaymentEvent paymentEvent) {
        if (paymentEvent.sdkEvent is SdkEvent_PaymentRefundable ||
            paymentEvent.sdkEvent is SdkEvent_PaymentRefundPending ||
            paymentEvent.sdkEvent is SdkEvent_PaymentRefunded) {
          listRefundables();
        }
      },
      onError: (Object e) => _logger.severe('Error in _listenRefundEvents', e),
    );
  }

  @override
  Future<void> close() {
    _paymentEventSubscription?.cancel();
    return super.close();
  }

  Future<RecommendedFees> recommendedFees() async {
    return await _breezSdkLiquid.instance!.recommendedFees();
  }

  Future<PrepareRefundResponse> prepareRefund({
    required PrepareRefundRequest req,
  }) async {
    return await _breezSdkLiquid.instance!.prepareRefund(req: req);
  }

  /// Fetches the current recommended fees for a refund transaction.
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required String toAddress,
    required String swapAddress,
  }) async {
    try {
      final RecommendedFees recommendedFees = await this.recommendedFees();
      return await _constructFeeOptionList(
        toAddress: toAddress,
        swapAddress: swapAddress,
        recommendedFees: recommendedFees,
      );
    } catch (e) {
      emit(RefundState(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  Future<List<RefundFeeOption>> _constructFeeOptionList({
    required String toAddress,
    required String swapAddress,
    required RecommendedFees recommendedFees,
  }) async {
    final List<BigInt> recommendedFeeList = <BigInt>[
      recommendedFees.hourFee,
      recommendedFees.halfHourFee,
      recommendedFees.fastestFee,
    ];
    final List<RefundFeeOption> feeOptions = await Future.wait(
      List<Future<RefundFeeOption>>.generate(3, (int index) async {
        final PrepareRefundRequest prepareRefundRequest = PrepareRefundRequest(
          swapAddress: swapAddress,
          feeRateSatPerVbyte: recommendedFeeList[index].toInt(),
          refundAddress: toAddress,
        );
        final PrepareRefundResponse prepareRefundResponse = await _prepareRefund(prepareRefundRequest);

        return RefundFeeOption(
          processingSpeed: ProcessingSpeed.values[index],
          feeRateSatPerVbyte: recommendedFeeList[index],
          prepareRefundResponse: prepareRefundResponse,
        );
      }),
    );

    return feeOptions;
  }

  Future<PrepareRefundResponse> _prepareRefund(PrepareRefundRequest req) async {
    try {
      _logger.info(
        'Preparing refund for swap ${req.swapAddress} to ${req.refundAddress} with fee ${req.feeRateSatPerVbyte}',
      );
      return await prepareRefund(req: req);
    } catch (e) {
      _logger.severe('Failed to prepare refund', e);
      rethrow;
    }
  }

  /// Broadcast a refund transaction for a failed/expired swap.
  Future<RefundResponse> refund({required RefundRequest req}) async {
    try {
      _logger.info(
        'Refunding swap ${req.swapAddress} to ${req.refundAddress} with fee ${req.feeRateSatPerVbyte}',
      );
      final RefundResponse refundResponse = await _breezSdkLiquid.instance!.refund(req: req);
      _logger.info('Refund txId: ${refundResponse.refundTxId}');
      emit(state.copyWith(refundTxId: refundResponse.refundTxId, error: ''));
      return refundResponse;
    } catch (e) {
      _logger.severe('Failed to refund swap', e);
      emit(state.copyWith(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }
}
