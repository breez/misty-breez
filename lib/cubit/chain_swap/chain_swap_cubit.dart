library chain_swap_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/chain_swap/chain_swap_state.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_option.dart';
import 'package:l_breez/utils/exceptions.dart';

export 'chain_swap_state.dart';

class ChainSwapCubit extends Cubit<ChainSwapState> {
  final BreezSDKLiquid _liquidSdk;

  ChainSwapCubit(this._liquidSdk) : super(ChainSwapState.initial());

  Future<RecommendedFees> recommendedFees() async {
    return await _liquidSdk.instance!.recommendedFees();
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

  Future<RefundResponse> refund({
    required RefundRequest req,
  }) async {
    return await _liquidSdk.instance!.refund(req: req);
  }

  Future<void> rescanOnchainSwaps() async {
    return await _liquidSdk.instance!.rescanOnchainSwaps();
  }

  /// Fetches the current recommended fees
  Future<List<SendChainSwapFeeOption>> fetchSendChainSwapFeeOptions({
    required int amountSat,
  }) async {
    RecommendedFees recommendedFees;
    try {
      recommendedFees = await this.recommendedFees();
      return await _constructFeeOptionList(
        amountSat: amountSat,
        recommendedFees: recommendedFees,
      );
    } catch (e) {
      emit(ChainSwapState(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  Future<List<SendChainSwapFeeOption>> _constructFeeOptionList({
    required int amountSat,
    required RecommendedFees recommendedFees,
  }) async {
    final recommendedFeeList = [
      recommendedFees.hourFee,
      recommendedFees.halfHourFee,
      recommendedFees.fastestFee,
    ];
    final feeOptions = await Future.wait(
      List.generate(3, (index) async {
        final recommendedFee = recommendedFeeList.elementAt(index);
        final preparePayOnchainRequest = PreparePayOnchainRequest(
          receiverAmountSat: BigInt.from(amountSat),
          satPerVbyte: recommendedFee.toInt(),
        );
        final swapOption = await preparePayOnchain(
          req: preparePayOnchainRequest,
        );

        return SendChainSwapFeeOption(
          txFeeSat: swapOption.claimFeesSat,
          processingSpeed: ProcessingSpeed.values.elementAt(index),
          satPerVbyte: recommendedFee,
          pairInfo: swapOption,
        );
      }),
    );

    emit(state.copyWith(feeOptions: feeOptions));
    return feeOptions;
  }

  void validateSwap(
    BigInt amount,
    bool outgoing,
    OnchainPaymentLimitsResponse onchainLimits,
    int balance,
  ) {
    if (outgoing && amount.toInt() > balance) {
      throw const InsufficientLocalBalanceError();
    }
    var limits = outgoing ? onchainLimits.send : onchainLimits.receive;
    if (amount > limits.maxSat) {
      throw PaymentExceededLimitError(limits.maxSat.toInt());
    }
    if (amount < limits.minSat) {
      throw PaymentBelowLimitError(limits.minSat.toInt());
    }
  }
}
