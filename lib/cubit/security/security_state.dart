import 'dart:convert';

import 'package:logging/logging.dart';

final Logger _logger = Logger('SecurityState');

/// Default auto-lock timeout in seconds
const int _kDefaultLockTimeout = 120;

/// Represents the status of PIN protection in the app
enum PinStatus {
  /// Initial state before user sets any preference
  initial,

  /// PIN protection is active
  enabled,

  /// PIN protection is explicitly disabled
  disabled,
}

/// Result of a PIN validation attempt
class ValidatePinResult {
  /// Whether the PIN validation was successful
  final bool success;

  /// Whether to clear the PIN input field after success
  final bool clearOnSuccess;

  /// Error message to display if validation failed
  final String? errorMessage;

  /// Create a new PIN test result
  ///
  /// [success] Whether the validation succeeded
  /// [clearOnSuccess] Whether to clear the PIN field after success
  /// [errorMessage] Error message to display if validation failed
  const ValidatePinResult(
    this.success, {
    this.clearOnSuccess = false,
    this.errorMessage,
  }) : assert(success || errorMessage != null, 'errorMessage must be provided if success is false');
}

/// Represents the type of biometric authentication available on the device
enum BiometricType {
  /// Generic face recognition (Android)
  face,

  /// Apple Face ID
  faceId,

  /// Generic fingerprint recognition (Android)
  fingerprint,

  /// Apple Touch ID
  touchId,

  /// Other biometric method not specifically categorized
  other,

  /// No biometric authentication available or disabled
  none,
}

/// Extension to provide helper methods for BiometricType
extension BiometricTypeExtension on BiometricType {
  /// Whether this is a facial recognition method (Face ID or generic face)
  bool get isFacial => this == BiometricType.face || this == BiometricType.faceId;

  /// Whether this is a fingerprint recognition method (Touch ID or generic fingerprint)
  bool get isFingerprint => this == BiometricType.fingerprint || this == BiometricType.touchId;

  /// Whether this is an uncategorized biometric method
  bool get isOtherBiometric => this == BiometricType.other;

  /// Whether any biometric method is available
  bool get isAvailable => this != BiometricType.none;
}

/// Represents the current lock state of the app
enum LockState {
  /// Initial state before any user interaction
  initial,

  /// App is locked and requires authentication
  locked,

  /// App is unlocked and accessible
  unlocked,
}

/// Represents whether the user has verified their recovery phrase/mnemonic
enum MnemonicStatus {
  /// Initial state before verification check
  initial,

  /// User has verified their recovery phrase
  verified,

  /// User has not yet verified their recovery phrase
  unverified,
}

/// Represents the complete security state of the application
class SecurityState {
  /// Current PIN protection status
  final PinStatus pinStatus;

  /// Time after which the app auto-locks when in background
  final Duration autoLockTimeout;

  /// Type of biometric authentication available/enabled
  final BiometricType biometricType;

  /// Current lock state of the app
  final LockState lockState;

  /// Recovery phrase verification status
  final MnemonicStatus mnemonicStatus;

  /// Creates a new SecurityState
  ///
  /// [pinStatus] Current PIN protection status
  /// [autoLockTimeout] Time after which app auto-locks when in background
  /// [biometricType] Type of biometric authentication available/enabled
  /// [lockState] Current lock state of the app
  /// [mnemonicStatus] Recovery phrase verification status
  const SecurityState({
    required this.pinStatus,
    required this.autoLockTimeout,
    required this.biometricType,
    required this.lockState,
    required this.mnemonicStatus,
  });

  /// Creates a default initial state
  const SecurityState.initial()
      : this(
          pinStatus: PinStatus.initial,
          autoLockTimeout: const Duration(seconds: _kDefaultLockTimeout),
          biometricType: BiometricType.none,
          lockState: LockState.initial,
          mnemonicStatus: MnemonicStatus.initial,
        );

  /// Creates a new SecurityState with specified fields updated
  SecurityState copyWith({
    PinStatus? pinStatus,
    Duration? autoLockTimeout,
    BiometricType? biometricType,
    LockState? lockState,
    MnemonicStatus? mnemonicStatus,
  }) {
    return SecurityState(
      pinStatus: pinStatus ?? this.pinStatus,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      biometricType: biometricType ?? this.biometricType,
      lockState: lockState ?? this.lockState,
      mnemonicStatus: mnemonicStatus ?? this.mnemonicStatus,
    );
  }

  /// Creates a SecurityState from JSON data
  ///
  /// [json] Map containing security state data
  factory SecurityState.fromJson(Map<String, dynamic> json) {
    try {
      return SecurityState(
        pinStatus: _parseEnum<PinStatus>(
          value: json['pinStatus'],
          enumValues: PinStatus.values,
          defaultValue: PinStatus.initial,
        ),
        autoLockTimeout: Duration(
          seconds: json['autoLockTimeout'] ?? _kDefaultLockTimeout,
        ),
        biometricType: _parseEnum<BiometricType>(
          value: json['biometricType'],
          enumValues: BiometricType.values,
          defaultValue: BiometricType.none,
        ),
        lockState: _parseEnum<LockState>(
          value: json['lockState'],
          enumValues: LockState.values,
          defaultValue: LockState.unlocked,
        ),
        mnemonicStatus: _parseEnum<MnemonicStatus>(
          value: json['mnemonicStatus'],
          enumValues: MnemonicStatus.values,
          defaultValue: MnemonicStatus.initial,
        ),
      );
    } catch (e) {
      _logger.severe('Error parsing SecurityState from JSON: $e');
      return const SecurityState.initial();
    }
  }

  /// Helper method to safely parse enum values from strings
  ///
  /// [value] String value to parse
  /// [enumValues] List of possible enum values
  /// [defaultValue] Default value to use if parsing fails
  static T _parseEnum<T extends Enum>({
    required String? value,
    required List<T> enumValues,
    required T defaultValue,
  }) {
    if (value == null) {
      return defaultValue;
    }

    try {
      return enumValues.firstWhere(
        (T e) => e.name == value,
        orElse: () => defaultValue,
      );
    } catch (_) {
      _logger.warning('Failed to parse enum value: $value, using default: ${defaultValue.name}');
      return defaultValue;
    }
  }

  /// Converts the state to JSON for persistence
  Map<String, dynamic> toJson() => <String, dynamic>{
        'pinStatus': pinStatus.name,
        'autoLockTimeout': autoLockTimeout.inSeconds,
        'biometricType': biometricType.name,
        'lockState': lockState.name,
        'mnemonicStatus': mnemonicStatus.name,
      };

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SecurityState &&
        other.pinStatus == pinStatus &&
        other.autoLockTimeout == autoLockTimeout &&
        other.biometricType == biometricType &&
        other.lockState == lockState &&
        other.mnemonicStatus == mnemonicStatus;
  }

  @override
  int get hashCode => Object.hash(
        pinStatus,
        autoLockTimeout,
        biometricType,
        lockState,
        mnemonicStatus,
      );
}
