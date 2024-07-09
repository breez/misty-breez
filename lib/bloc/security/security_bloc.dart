import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/bloc/security/security_state.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:logging/logging.dart';

class SecurityBloc extends Cubit<SecurityState> with HydratedMixin {
  final _log = Logger("LocalAuthenticationService");
  final _auth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  Timer? _autoLock;

  SecurityBloc() : super(const SecurityState.initial()) {
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
    await _secureStorage.write(key: "pinCode", value: pin);
    emit(state.copyWith(
      pinStatus: PinStatus.enabled,
    ));
  }

  Future<bool> testPin(String pin) async {
    final storedPin = await _secureStorage.read(key: "pinCode");
    if (storedPin == null) {
      _setLockState(LockState.locked);
      throw SecurityStorageException();
    }
    return storedPin == pin;
  }

  Future clearPin() async {
    await _secureStorage.delete(key: "pinCode");
    emit(state.copyWith(
      pinStatus: PinStatus.disabled,
    ));
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
      _log.severe("Error Code: ${error.code} - Message: ${error.message}", error);
      await _auth.stopAuthentication();
      _setLockState(LockState.locked);
      return false;
    }
  }

  void _setLockState(LockState lockState) {
    emit(state.copyWith(
      lockState: lockState,
    ));
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
}

class SecurityStorageException implements Exception {}
