import 'package:l_breez/cubit/ln_address/models/ln_address_update_status.dart';

enum LnAddressStatus { initial, loading, success, error }

class LnAddressState {
  final String? lnurl;
  final String? lnAddress;
  final LnAddressStatus status;
  final LnAddressUpdateStatus updateStatus;
  final Object? error;

  const LnAddressState({
    this.lnurl,
    this.lnAddress,
    this.status = LnAddressStatus.initial,
    this.updateStatus = const LnAddressUpdateStatus(),
    this.error,
  });

  LnAddressState copyWith({
    String? lnurl,
    String? lnAddress,
    LnAddressStatus? status,
    LnAddressUpdateStatus? updateStatus,
    Object? error,
  }) {
    return LnAddressState(
      lnurl: lnurl ?? this.lnurl,
      lnAddress: lnAddress ?? this.lnAddress,
      status: status ?? this.status,
      updateStatus: updateStatus ?? this.updateStatus,
      error: error ?? this.error,
    );
  }
}
