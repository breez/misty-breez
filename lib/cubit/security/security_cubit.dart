library security_cubit;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:keychain/keychain.dart';
import 'package:l_breez/cubit/security/security_cubit.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:logging/logging.dart';

export 'security_state.dart';

final _logger = Logger("SecurityCubit");

const String pinCodeKey = "pinCode";

class SecurityCubit extends Cubit<SecurityState> with HydratedMixin {
  final KeyChain keyChain;

  final _auth = LocalAuthentication();
  Timer? _autoLock;

  SecurityCubit(this.keyChain) : super(const SecurityState.initial()) {
    hydrate();
    FGBGEvents.stream.listen((event) {
      final lockInterval = state.lockInterval;
      if (event == FGBGType.foreground) {
        _autoLock?.cancel();
        _autoLock = null;
      } else {
        if (state.pinStatus == PinStatus.enabled) {
          _autoLock = Timer(lockInterval, () {
            _setLockState(LockState.locked);
            _autoLock = null;
          });
        }
      }
    });
  }

  Future setPin(String pin) async {
    await keyChain.write(pinCodeKey, pin);
    emit(state.copyWith(pinStatus: PinStatus.enabled));
  }

  Future<bool> testPin(String pin) async {
    final storedPin = await keyChain.read(pinCodeKey);
    if (storedPin == null) {
      _setLockState(LockState.locked);
      throw SecurityStorageException();
    }
    return storedPin == pin;
  }

  Future clearPin() async {
    await keyChain.delete(pinCodeKey);
    emit(state.copyWith(pinStatus: PinStatus.disabled));
    _setLockState(LockState.unlocked);
  }

  Future setLockInterval(Duration lockInterval) async {
    emit(state.copyWith(
      lockInterval: lockInterval,
    ));
    _setLockState(LockState.unlocked);
  }

  Future clearLocalAuthentication() async {
    emit(state.copyWith(
      localAuthenticationOption: LocalAuthenticationOption.none,
    ));
    _setLockState(LockState.unlocked);
  }

  Future enableLocalAuthentication() async {
    emit(state.copyWith(
      localAuthenticationOption: await localAuthenticationOption(),
    ));
    _setLockState(LockState.unlocked);
  }

  Future<LocalAuthenticationOption> localAuthenticationOption() async {
    final availableBiometrics = await _auth.getAvailableBiometrics();
    if (availableBiometrics.contains(BiometricType.face)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? LocalAuthenticationOption.faceId
          : LocalAuthenticationOption.face;
    }
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? LocalAuthenticationOption.touchId
          : LocalAuthenticationOption.fingerprint;
    }
    final otherBiometrics = await _auth.isDeviceSupported();
    return otherBiometrics ? LocalAuthenticationOption.other : LocalAuthenticationOption.none;
  }

  Future<bool> localAuthentication(String localizedReason) async {
    try {
      final authenticated = await _auth.authenticate(
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: false,
        ),
        localizedReason: localizedReason,
        authMessages: const [
          AndroidAuthMessages(),
          IOSAuthMessages(),
        ],
      );
      _setLockState(authenticated ? LockState.unlocked : LockState.locked);
      return authenticated;
    } on PlatformException catch (error) {
      if (error.code == "LockedOut" || error.code == "PermanentlyLockedOut") {
        throw error.message!;
      }
      _logger.severe("Error Code: ${error.code} - Message: ${error.message}", error);
      await _auth.stopAuthentication();
      _setLockState(LockState.locked);
      return false;
    }
  }

  void _setLockState(LockState lockState) {
    emit(state.copyWith(lockState: lockState));
  }

  @override
  SecurityState? fromJson(Map<String, dynamic> json) {
    final state = SecurityState.fromJson(json);
    _setLockState(state.pinStatus == PinStatus.enabled ? LockState.locked : LockState.unlocked);
    return state;
  }

  @override
  Map<String, dynamic>? toJson(SecurityState state) {
    return state.toJson();
  }

  void mnemonicsValidated() {
    emit(state.copyWith(verificationStatus: VerificationStatus.verified));
  }
}

class SecurityStorageException implements Exception {}
