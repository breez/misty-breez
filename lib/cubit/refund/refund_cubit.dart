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
    _logger.info('Initializing Refund Cubit');
    _breezSdkLiquid.getInfoResponseStream.first.then((_) => listRefundables()).catchError(
      (Object e) {
        _logger.severe('Failed to initialize Refund Cubit', e);
      },
    );
  }

  void listRefundables() async {
    try {
      _logger.info('Refreshing refundables');
      final List<RefundableSwap> refundables = await _breezSdkLiquid.instance!.listRefundables();
      _logger.info('Fetched refundables: $refundables');
      emit(state.copyWith(refundables: refundables));
    } catch (e) {
      _logger.severe('Failed to list refundables', e);
      emit(state.copyWith());
    }
  }

  void _listenRefundEvents() {
    _logger.info('Listening to Refund-related events');
    _paymentEventSubscription = _breezSdkLiquid.paymentEventStream.listen(
      (PaymentEvent paymentEvent) {
        _logger.info('Received payment event: $paymentEvent');
        if (paymentEvent.sdkEvent.isRefundRelated(hasRefundables: state.hasRefundables)) {
          _logger.info('Refund-related event detected. Refreshing refundables.');
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

  Future<RecommendedFees> _recommendedFees() async {
    try {
      _logger.info('Fetching recommended fees');
      final RecommendedFees fees = await _breezSdkLiquid.instance!.recommendedFees();
      _logger.info('Fetched recommended fees: $fees');
      return fees;
    } catch (e) {
      _logger.severe('Failed to fetch recommended fees', e);
      rethrow;
    }
  }

  /// Fetches the current recommended fees for a refund transaction.
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required String toAddress,
    required String swapAddress,
  }) async {
    try {
      _logger.info('Fetching refund fee options for swapAddress: $swapAddress toAddress: $toAddress');
      final RecommendedFees recommendedFees = await _recommendedFees();
      final List<RefundFeeOption> feeOptions = await _constructFeeOptionList(
        toAddress: toAddress,
        swapAddress: swapAddress,
        recommendedFees: recommendedFees,
      );
      _logger.info('Constructed fee options: $feeOptions');
      return feeOptions;
    } catch (e) {
      _logger.severe('Failed to fetch refund fee options', e);
      emit(RefundState(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  Future<List<RefundFeeOption>> _constructFeeOptionList({
    required String toAddress,
    required String swapAddress,
    required RecommendedFees recommendedFees,
  }) async {
    _logger.info('Constructing refund fee options for swapAddress: $swapAddress');

    final List<BigInt> recommendedFeeList = <BigInt>[
      recommendedFees.hourFee,
      recommendedFees.halfHourFee,
      recommendedFees.fastestFee,
    ];

    try {
      final List<RefundFeeOption> feeOptions = await Future.wait(
        List<Future<RefundFeeOption>>.generate(3, (int index) async {
          final PrepareRefundRequest prepareRefundRequest = PrepareRefundRequest(
            swapAddress: swapAddress,
            feeRateSatPerVbyte: recommendedFeeList[index].toInt(),
            refundAddress: toAddress,
          );
          final PrepareRefundResponse prepareRefundResponse = await prepareRefund(prepareRefundRequest);

          return RefundFeeOption(
            processingSpeed: ProcessingSpeed.values[index],
            feeRateSatPerVbyte: recommendedFeeList[index],
            prepareRefundResponse: prepareRefundResponse,
          );
        }),
      );

      _logger.info('Successfully constructed refund fee options: $feeOptions');
      return feeOptions;
    } catch (e) {
      _logger.severe('Failed to construct refund fee options', e);
      rethrow;
    }
  }

  Future<PrepareRefundResponse> prepareRefund(PrepareRefundRequest req) async {
    try {
      _logger.info(
        'Preparing refund for swap ${req.swapAddress} to ${req.refundAddress} with fee ${req.feeRateSatPerVbyte}',
      );
      final PrepareRefundResponse response = await _breezSdkLiquid.instance!.prepareRefund(req: req);
      _logger.info('Prepared refund response: $response');
      return response;
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
      _logger.info('Refund succeeded. txId: ${refundResponse.refundTxId}');
      emit(state.copyWith(refundTxId: refundResponse.refundTxId, error: ''));
      return refundResponse;
    } catch (e) {
      _logger.severe('Failed to refund swap', e);
      emit(state.copyWith(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }
}
