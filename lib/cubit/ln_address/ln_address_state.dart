import 'package:l_breez/cubit/ln_address/models/ln_address_update_status.dart';

/// Status of Lightning Address operations
enum LnAddressStatus {
  /// Initial state or reset state
  initial,

  /// Operation in progress
  loading,

  /// Operation completed successfully
  success,

  /// Operation failed
  error
}

/// Represents the state of a Lightning Address in the application.
///
/// This class contains all information related to the current Lightning Address
/// including its LNURL, address string, operation status, and error information.
class LnAddressState {
  /// The LNURL associated with this Lightning Address
  final String? lnurl;

  /// The formatted Lightning Address (username@domain)
  final String? lnAddress;

  /// Current status of Lightning Address operations
  final LnAddressStatus status;

  /// Status information for update operations
  final LnAddressUpdateStatus updateStatus;

  /// Error object if any operation has failed
  final Object? error;

  /// Creates a new Lightning Address state
  ///
  /// All parameters are optional. Status defaults to [LnAddressStatus.initial]
  /// and updateStatus defaults to an empty update status.
  const LnAddressState({
    this.lnurl,
    this.lnAddress,
    this.status = LnAddressStatus.initial,
    this.updateStatus = const LnAddressUpdateStatus(),
    this.error,
  });

  /// Creates a copy of this state with optional updated fields
  ///
  /// Returns a new [LnAddressState] with the specified fields updated
  /// and all other fields maintaining their existing values.
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

  /// Creates a copy of this state with errors cleared
  ///
  /// Returns a new [LnAddressState] with error set to null
  /// and all other fields maintaining their existing values.
  LnAddressState clearError() {
    return LnAddressState(
      lnurl: lnurl,
      lnAddress: lnAddress,
      status: status,
      updateStatus: updateStatus,
    );
  }

  /// Creates a copy of this state with update status reset to initial
  ///
  /// Useful for clearing previous update operation results.
  LnAddressState clearUpdateStatus() {
    return LnAddressState(
      lnurl: lnurl,
      lnAddress: lnAddress,
      status: status,
      error: error,
    );
  }

  /// Determines if this state has a valid Lightning Address
  ///
  /// Returns true if the lnAddress is not null and not empty
  bool get hasValidAddress => lnAddress != null && lnAddress!.isNotEmpty;

  /// Determines if this state has a valid LNURL
  ///
  /// Returns true if the lnurl is not null and not empty
  bool get hasValidLnUrl => lnurl != null && lnurl!.isNotEmpty;

  /// Checks if this state represents an error condition
  ///
  /// Returns true if status is [LnAddressStatus.error] or error is not null
  bool get hasError => status == LnAddressStatus.error || error != null;

  /// Checks if this state is in a loading condition
  ///
  /// Returns true if status is [LnAddressStatus.loading]
  bool get isLoading => status == LnAddressStatus.loading;

  /// Checks if this state represents a successful operation
  ///
  /// Returns true if status is [LnAddressStatus.success]
  bool get isSuccess => status == LnAddressStatus.success;

  /// Extracts the username portion from the Lightning Address
  ///
  /// Returns the part before the '@' symbol or null if address is invalid
  String? get username {
    if (!hasValidAddress) {
      return null;
    }
    final List<String> parts = lnAddress!.split('@');
    return parts.isNotEmpty ? parts[0] : null;
  }

  /// Extracts the domain portion from the Lightning Address
  ///
  /// Returns the part after the '@' symbol or null if address is invalid
  String? get domain {
    if (!hasValidAddress) {
      return null;
    }
    final List<String> parts = lnAddress!.split('@');
    return parts.length > 1 ? parts[1] : null;
  }

  @override
  String toString() {
    return 'LnAddressState(lnAddress: $lnAddress, status: $status, '
        'updateStatus: $updateStatus, hasError: $hasError)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is LnAddressState &&
        other.lnurl == lnurl &&
        other.lnAddress == lnAddress &&
        other.status == status &&
        other.updateStatus == updateStatus &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      lnurl,
      lnAddress,
      status,
      updateStatus,
      error,
    );
  }
}
