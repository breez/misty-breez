class AmountlessBtcState {
  final String? address;
  final int? estimateFees;
  final bool isLoading;
  final Object? error;

  const AmountlessBtcState({this.address, this.estimateFees, this.isLoading = false, this.error});

  AmountlessBtcState.initial() : this();

  AmountlessBtcState copyWith({String? address, int? estimateFees, bool? isLoading, Object? error}) =>
      AmountlessBtcState(
        address: address ?? this.address,
        estimateFees: estimateFees ?? this.estimateFees,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get hasValidAddress => address != null && address!.isNotEmpty;
  bool get hasError => error != null;

  @override
  String toString() =>
      'AmountlessBtcState(address: $address, estimateFees: $estimateFees, isLoading: $isLoading, error: $error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AmountlessBtcState &&
        other.address == address &&
        other.estimateFees == estimateFees &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(address, estimateFees, isLoading, error);
}
