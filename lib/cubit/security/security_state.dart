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

enum LockState {
  initial,
  locked,
  unlocked,
}

class SecurityState {
  final PinStatus pinStatus;
  final Duration lockInterval;
  final LocalAuthenticationOption localAuthenticationOption;
  final LockState lockState;

  const SecurityState(
    this.pinStatus,
    this.lockInterval,
    this.localAuthenticationOption,
    this.lockState,
  );

  const SecurityState.initial()
      : this(
          PinStatus.initial,
          const Duration(seconds: _kDefaultLockInterval),
          LocalAuthenticationOption.none,
          LockState.initial,
        );

  SecurityState copyWith({
    PinStatus? pinStatus,
    Duration? lockInterval,
    LocalAuthenticationOption? localAuthenticationOption,
    LockState? lockState,
  }) {
    return SecurityState(
      pinStatus ?? this.pinStatus,
      lockInterval ?? this.lockInterval,
      localAuthenticationOption ?? this.localAuthenticationOption,
      lockState ?? this.lockState,
    );
  }

  SecurityState.fromJson(Map<String, dynamic> json)
      : pinStatus = PinStatus.values.byName(json['pinStatus'] ?? PinStatus.initial.name),
        lockInterval = Duration(seconds: json['lockInterval'] ?? _kDefaultLockInterval),
        localAuthenticationOption = LocalAuthenticationOption.values
            .byName(json['localAuthenticationOption'] ?? LocalAuthenticationOption.none.name),
        lockState = LockState.values.byName(json['lockState'] ?? LockState.unlocked.name);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pinStatus': pinStatus.name,
        'lockInterval': lockInterval.inSeconds,
        'localAuthenticationOption': localAuthenticationOption.name,
        'lockState': lockState.name,
      };

  @override
  String toString() => jsonEncode(toJson());
}
