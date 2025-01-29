enum UpdateStatus { initial, loading, success, error }

class LnAddressUpdateStatus {
  final UpdateStatus status;
  final Object? error;
  final String? errorMessage;

  const LnAddressUpdateStatus({
    this.status = UpdateStatus.initial,
    this.error,
    this.errorMessage,
  });

  LnAddressUpdateStatus copyWith({
    UpdateStatus? status,
    Object? error,
    String? errorMessage,
  }) {
    return LnAddressUpdateStatus(
      status: status ?? this.status,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
