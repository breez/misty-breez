import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/utils.dart';

export 'chain_swap_state.dart';

final Logger _logger = Logger('ChainSwapCubit');

class ChainSwapCubit extends Cubit<ChainSwapState> {
  final BreezSDKLiquid _breezSdkLiquid;

  ChainSwapCubit(this._breezSdkLiquid) : super(ChainSwapState.initial()) {
    _initializeChainSwapCubit();
  }

  void _initializeChainSwapCubit() {
    _breezSdkLiquid.getInfoResponseStream.first.then((_) => rescanOnchainSwaps());
  }

  Future<void> rescanOnchainSwaps() async {
    try {
      _logger.info('Rescanning onchain swaps');
      return await _breezSdkLiquid.instance!.rescanOnchainSwaps();
    } catch (e) {
      _logger.severe('Failed to rescan onchain swaps', e);
      rethrow;
    }
  }

  Future<SendPaymentResponse> payOnchain({required PayOnchainRequest req}) async {
    try {
      _logger.info(
        'Paying onchain ${req.address} to ${req.prepareResponse.receiverAmountSat} with fee ${req.prepareResponse.totalFeesSat}',
      );
      return await _breezSdkLiquid.instance!.payOnchain(req: req);
    } catch (e) {
      _logger.severe('Failed to pay onchain', e);
      emit(state.copyWith(error: ExceptionHandler.extractMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  /// Fetches the current recommended fees for a chain swap transaction
  Future<List<SendChainSwapFeeOption>> fetchSendChainSwapFeeOptions({
    required int amountSat,
    required bool isDrain,
  }) async {
    try {
      final RecommendedFees recommendedFees = await _breezSdkLiquid.instance!.recommendedFees();
      return _constructFeeOptionList(
        amountSat: amountSat,
        isDrain: isDrain,
        recommendedFees: recommendedFees,
      );
    } catch (e) {
      emit(ChainSwapState(error: ExceptionHandler.extractMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  Future<List<SendChainSwapFeeOption>> _constructFeeOptionList({
    required int amountSat,
    required bool isDrain,
    required RecommendedFees recommendedFees,
  }) async {
    final List<BigInt> recommendedFeeList = <BigInt>[
      recommendedFees.hourFee,
      recommendedFees.halfHourFee,
      recommendedFees.fastestFee,
    ];
    final List<SendChainSwapFeeOption> feeOptions = await Future.wait(
      List<Future<SendChainSwapFeeOption>>.generate(3, (int index) async {
        final PayAmount payAmount = isDrain
            ? const PayAmount_Drain()
            : PayAmount_Bitcoin(receiverAmountSat: BigInt.from(amountSat));
        final PreparePayOnchainRequest preparePayOnchainRequest = PreparePayOnchainRequest(
          amount: payAmount,
          feeRateSatPerVbyte: recommendedFeeList[index].toInt(),
        );
        final PreparePayOnchainResponse preparePayOnchainResponse = await _preparePayOnchain(
          preparePayOnchainRequest,
        );

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
      _logger.info('Preparing pay onchain for amount: ${req.amount} with fee ${req.feeRateSatPerVbyte}');
      return await _breezSdkLiquid.instance!.preparePayOnchain(req: req);
    } catch (e) {
      _logger.severe('Failed to prepare pay onchain', e);
      rethrow;
    }
  }

  void validateSwap(BigInt amount, bool outgoing, OnchainPaymentLimitsResponse onchainLimits, int balance) {
    if (outgoing && amount.toInt() > balance) {
      throw const InsufficientLocalBalanceError();
    }
    final Limits limits = outgoing ? onchainLimits.send : onchainLimits.receive;
    if (amount > limits.maxSat) {
      throw PaymentExceedsLimitError(limits.maxSat.toInt());
    }
    if (amount < limits.minSat) {
      throw PaymentBelowLimitError(limits.minSat.toInt());
    }
  }
}
