library refund_cubit;

import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/model/models.dart';
import 'package:l_breez/cubit/refund/refund_state.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

export 'refund_state.dart';

final _log = Logger("RefundCubit");

class RefundCubit extends Cubit<RefundState> {
  StreamSubscription? _paymentEventSubscription;

  final BreezSDKLiquid _liquidSdk;

  RefundCubit(this._liquidSdk) : super(RefundState.initial()) {
    _initializeRefundCubit();
    _listenRefundEvents();
  }

  void _initializeRefundCubit() {
    _liquidSdk.walletInfoStream.first.then((_) => listRefundables());
  }

  void listRefundables() async {
    try {
      _log.info('Refreshing refundables');
      var refundables = await _liquidSdk.instance!.listRefundables();
      _log.info('Refundables: $refundables');
      emit(state.copyWith(refundables: refundables));
    } catch (e) {
      _log.severe('Failed to list refundables', e);
      emit(state.copyWith(refundables: null));
    }
  }

  void _listenRefundEvents() {
    _log.info('Listening to Refund events');
    _paymentEventSubscription = _liquidSdk.paymentEventStream.listen(
      (paymentEvent) {
        if (paymentEvent.sdkEvent is SdkEvent_PaymentRefunded ||
            paymentEvent.sdkEvent is SdkEvent_PaymentRefundPending) {
          listRefundables();
        }
      },
      onError: (e) => _log.severe('Error in _listenRefundEvents', e),
    );
  }

  @override
  Future<void> close() {
    _paymentEventSubscription?.cancel();
    return super.close();
  }

  Future<RecommendedFees> recommendedFees() async {
    return await _liquidSdk.instance!.recommendedFees();
  }

  Future<PrepareRefundResponse> prepareRefund({
    required PrepareRefundRequest req,
  }) async {
    return await _liquidSdk.instance!.prepareRefund(req: req);
  }

  /// Fetches the current recommended fees for a refund transaction.
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required String toAddress,
    required String swapAddress,
  }) async {
    try {
      final recommendedFees = await this.recommendedFees();
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
    final recommendedFeeList = [
      recommendedFees.hourFee,
      recommendedFees.halfHourFee,
      recommendedFees.fastestFee,
    ];
    final feeOptions = await Future.wait(
      List.generate(3, (index) async {
        final prepareRefundRequest = PrepareRefundRequest(
          swapAddress: swapAddress,
          feeRateSatPerVbyte: recommendedFeeList[index].toInt(),
          refundAddress: toAddress,
        );
        final prepareRefundResponse = await _prepareRefund(prepareRefundRequest);

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
      _log.info(
        "Preparing refund for swap ${req.swapAddress} to ${req.refundAddress} with fee ${req.feeRateSatPerVbyte}",
      );
      return await prepareRefund(req: req);
    } catch (e) {
      _log.severe("Failed to prepare refund", e);
      rethrow;
    }
  }

  /// Broadcast a refund transaction for a failed/expired swap.
  Future<RefundResponse> refund({required RefundRequest req}) async {
    try {
      _log.info(
        "Refunding swap ${req.swapAddress} to ${req.refundAddress} with fee ${req.feeRateSatPerVbyte}",
      );
      final refundResponse = await _liquidSdk.instance!.refund(req: req);
      _log.info("Refund txId: ${refundResponse.refundTxId}");
      emit(state.copyWith(refundTxId: refundResponse.refundTxId, error: ""));
      return refundResponse;
    } catch (e) {
      _log.severe("Failed to refund swap", e);
      emit(state.copyWith(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }
}
