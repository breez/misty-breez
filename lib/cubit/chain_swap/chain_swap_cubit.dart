library chain_swap_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/chain_swap/chain_swap_state.dart';
import 'package:l_breez/cubit/model/models.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

export 'chain_swap_state.dart';

final _log = Logger("ChainSwapCubit");

class ChainSwapCubit extends Cubit<ChainSwapState> {
  final BreezSDKLiquid _liquidSdk;

  ChainSwapCubit(this._liquidSdk) : super(ChainSwapState.initial()) {
    _initializeChainSwapCubit();
  }

  void _initializeChainSwapCubit() {
    _liquidSdk.walletInfoStream.first.then((_) => rescanOnchainSwaps());
  }

  Future<void> rescanOnchainSwaps() async {
    try {
      _log.info("Rescanning onchain swaps");
      return await _liquidSdk.instance!.rescanOnchainSwaps();
    } catch (e) {
      _log.severe("Failed to rescan onchain swaps", e);
      rethrow;
    }
  }

  Future<SendPaymentResponse> payOnchain({
    required PayOnchainRequest req,
  }) async {
    try {
      _log.info(
        "Paying onchain ${req.address} to ${req.prepareResponse.receiverAmountSat} with fee ${req.prepareResponse.totalFeesSat}",
      );
      return await _liquidSdk.instance!.payOnchain(req: req);
    } catch (e) {
      _log.severe("Failed to pay onchain", e);
      emit(state.copyWith(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  /// Fetches the current recommended fees for a chain swap transaction
  Future<List<SendChainSwapFeeOption>> fetchSendChainSwapFeeOptions({
    required int amountSat,
    required bool isDrain,
  }) async {
    try {
      final recommendedFees = await _liquidSdk.instance!.recommendedFees();
      return _constructFeeOptionList(
        amountSat: amountSat,
        isDrain: isDrain,
        recommendedFees: recommendedFees,
      );
    } catch (e) {
      emit(ChainSwapState(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  Future<List<SendChainSwapFeeOption>> _constructFeeOptionList({
    required int amountSat,
    required bool isDrain,
    required RecommendedFees recommendedFees,
  }) async {
    final recommendedFeeList = [
      recommendedFees.hourFee,
      recommendedFees.halfHourFee,
      recommendedFees.fastestFee,
    ];
    final feeOptions = await Future.wait(
      List.generate(3, (index) async {
        final payOnchainAmount = isDrain
            ? const PayOnchainAmount_Drain()
            : PayOnchainAmount_Receiver(amountSat: BigInt.from(amountSat));
        final preparePayOnchainRequest = PreparePayOnchainRequest(
          amount: payOnchainAmount,
          feeRateSatPerVbyte: recommendedFeeList[index].toInt(),
        );
        final preparePayOnchainResponse = await _preparePayOnchain(preparePayOnchainRequest);

        return SendChainSwapFeeOption(
          processingSpeed: ProcessingSpeed.values[index],
          feeRateSatPerVbyte: recommendedFeeList[index],
          preparePayOnchainResponse: preparePayOnchainResponse,
        );
      }),
    );

    return feeOptions;
  }

  Future<PreparePayOnchainResponse> _preparePayOnchain(PreparePayOnchainRequest req) async {
    try {
      _log.info(
        "Preparing pay onchain for amount: ${req.amount} with fee ${req.feeRateSatPerVbyte}",
      );
      return await _liquidSdk.instance!.preparePayOnchain(req: req);
    } catch (e) {
      _log.severe("Failed to prepare pay onchain", e);
      rethrow;
    }
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
