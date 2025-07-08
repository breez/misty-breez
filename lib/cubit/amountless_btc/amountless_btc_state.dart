class AmountlessBtcState {
  final String? address;
  final int? estimateBaseFeeSat;
  final double? estimateProportionalFee;
  final bool isLoading;
  final Object? error;

  const AmountlessBtcState({
    this.address,
    this.estimateBaseFeeSat,
    this.estimateProportionalFee,
    this.isLoading = false,
    this.error,
  });

  AmountlessBtcState.initial() : this();

  AmountlessBtcState copyWith({
    String? address,
    int? estimateBaseFeeSat,
    double? estimateProportionalFee,
    bool? isLoading,
    Object? error,
  }) => AmountlessBtcState(
    address: address ?? this.address,
    estimateBaseFeeSat: estimateBaseFeeSat ?? this.estimateBaseFeeSat,
    estimateProportionalFee: estimateProportionalFee ?? this.estimateProportionalFee,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  bool get hasValidAddress => address != null && address!.isNotEmpty;
  bool get hasError => error != null;

  @override
  String toString() =>
      'AmountlessBtcState('
      'address: ${address ?? "N/A"}, '
      'estimateBaseFeeSat: ${estimateBaseFeeSat ?? "N/A"}, '
      'estimateProportionalFee: ${estimateProportionalFee ?? "N/A"}'
      'isLoading: $isLoading, '
      'error: ${error ?? "N/A"}'
      ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AmountlessBtcState &&
        other.address == address &&
        other.estimateBaseFeeSat == estimateBaseFeeSat &&
        other.estimateProportionalFee == estimateProportionalFee &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(address, estimateBaseFeeSat, estimateProportionalFee, isLoading, error);
}
