import 'package:l_breez/cubit/model/models.dart';

class ChainSwapState {
  final List<SendChainSwapFeeOption> feeOptions;
  final String? error;

  ChainSwapState({this.feeOptions = const <SendChainSwapFeeOption>[], this.error = ''});

  ChainSwapState.initial() : this();

  ChainSwapState copyWith({
    List<SendChainSwapFeeOption>? feeOptions,
    String? error,
  }) =>
      ChainSwapState(
        feeOptions: feeOptions ?? this.feeOptions,
        error: error ?? this.error,
      );
}
