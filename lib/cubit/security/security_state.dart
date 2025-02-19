import 'dart:convert';

const int _kDefaultLockInterval = 120;

enum PinStatus {
  initial,
  enabled,
  disabled,
}

enum LocalAuthenticationOption {
  face,
  faceId,
  fingerprint,
  touchId,
  other,
  none,
}

extension LocalAuthenticationOptionExtension on LocalAuthenticationOption {
  bool get isFacial => this == LocalAuthenticationOption.face || this == LocalAuthenticationOption.faceId;

  bool get isFingerprint =>
      this == LocalAuthenticationOption.fingerprint || this == LocalAuthenticationOption.touchId;

  bool get isOtherBiometric => this == LocalAuthenticationOption.other;
}

enum LockState { initial, locked, unlocked }

enum VerificationStatus { initial, verified, unverified }

class SecurityState {
  final PinStatus pinStatus;
  final Duration lockInterval;
  final LocalAuthenticationOption localAuthenticationOption;
  final LockState lockState;
  final VerificationStatus verificationStatus;

  const SecurityState(
    this.pinStatus,
    this.lockInterval,
    this.localAuthenticationOption,
    this.lockState,
    this.verificationStatus,
  );

  const SecurityState.initial()
      : this(
          PinStatus.initial,
          const Duration(seconds: _kDefaultLockInterval),
          LocalAuthenticationOption.none,
          LockState.initial,
          VerificationStatus.initial,
        );

  SecurityState copyWith({
    PinStatus? pinStatus,
    Duration? lockInterval,
    LocalAuthenticationOption? localAuthenticationOption,
    LockState? lockState,
    VerificationStatus? verificationStatus,
  }) {
    return SecurityState(
      pinStatus ?? this.pinStatus,
      lockInterval ?? this.lockInterval,
      localAuthenticationOption ?? this.localAuthenticationOption,
      lockState ?? this.lockState,
      verificationStatus ?? this.verificationStatus,
    );
  }

  SecurityState.fromJson(Map<String, dynamic> json)
      : pinStatus = PinStatus.values.byName(json['pinStatus'] ?? PinStatus.initial.name),
        lockInterval = Duration(seconds: json['lockInterval'] ?? _kDefaultLockInterval),
        localAuthenticationOption = LocalAuthenticationOption.values
            .byName(json['localAuthenticationOption'] ?? LocalAuthenticationOption.none.name),
        lockState = LockState.values.byName(json['lockState'] ?? LockState.unlocked.name),
        verificationStatus =
            VerificationStatus.values.byName(json['verificationStatus'] ?? VerificationStatus.initial.name);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pinStatus': pinStatus.name,
        'lockInterval': lockInterval.inSeconds,
        'localAuthenticationOption': localAuthenticationOption.name,
        'lockState': lockState.name,
        'verificationStatus': verificationStatus.name,
      };

  @override
  String toString() => jsonEncode(toJson());
}
