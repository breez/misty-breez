class LiquidAddressState {
  final String? address;
  final bool isLoading;
  final Object? error;

  const LiquidAddressState({this.address, this.isLoading = false, this.error});

  LiquidAddressState.initial() : this();

  LiquidAddressState copyWith({String? address, bool? isLoading, Object? error}) => LiquidAddressState(
    address: address ?? this.address,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  bool get hasValidAddress => address != null && address!.isNotEmpty;
  bool get hasError => error != null;

  @override
  String toString() =>
      'LiquidAddressState('
      'address: ${address ?? "N/A"}, '
      'isLoading: $isLoading, '
      'error: ${error ?? "N/A"}'
      ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is LiquidAddressState &&
        other.address == address &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(address, isLoading, error);
}
