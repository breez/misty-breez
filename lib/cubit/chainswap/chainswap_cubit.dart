import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/account/breez_sdk_liquid.dart';
import 'package:l_breez/cubit/account/payment_error.dart';
import 'package:l_breez/cubit/chainswap/chainswap_state.dart';

class ChainSwapCubit extends Cubit<ChainSwapState> {
  final BreezSDKLiquid _liquidSdk;

  ChainSwapCubit(this._liquidSdk) : super(ChainSwapState.initial());

  Future<OnchainPaymentLimitsResponse> fetchOnchainLimits() async {
    return await _liquidSdk.instance!.fetchOnchainLimits();
  }

  Future<PreparePayOnchainResponse> preparePayOnchain({
    required PreparePayOnchainRequest req,
  }) async {
    return await _liquidSdk.instance!.preparePayOnchain(req: req);
  }

  Future<SendPaymentResponse> payOnchain({
    required PayOnchainRequest req,
  }) async {
    return await _liquidSdk.instance!.payOnchain(req: req);
  }

  Future<PrepareReceiveOnchainResponse> prepareReceiveOnchain({
    required PrepareReceiveOnchainRequest req,
  }) async {
    return await _liquidSdk.instance!.prepareReceiveOnchain(req: req);
  }

  Future<ReceiveOnchainResponse> receiveOnchain({
    required PrepareReceiveOnchainResponse req,
  }) async {
    return await _liquidSdk.instance!.receiveOnchain(req: req);
  }

  Future<RefundResponse> refund({
    required RefundRequest req,
  }) async {
    return await _liquidSdk.instance!.refund(req: req);
  }

  Future<void> rescanOnchainSwaps() async {
    return await _liquidSdk.instance!.rescanOnchainSwaps();
  }

  void validateSwap(
    BigInt amount,
    bool outgoing,
    OnchainPaymentLimitsResponse onchainLimits,
  ) {
    var limits = outgoing ? onchainLimits.send : onchainLimits.receive;
    if (amount > limits.maxSat) {
      throw PaymentExceededLimitError(limits.maxSat);
    }
    if (amount < limits.minSat) {
      throw PaymentBelowLimitError(limits.minSat);
    }
  }
}
