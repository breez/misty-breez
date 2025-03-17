import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:keychain/keychain.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:logging/logging.dart';

export 'mnemonic_verification_status_preferences.dart';
export 'security_state.dart';

final Logger _logger = Logger('SecurityCubit');

const String pinCodeKey = 'pinCode';

class SecurityCubit extends Cubit<SecurityState> with HydratedMixin<SecurityState> {
  final KeyChain keyChain;

  final LocalAuthentication _auth = LocalAuthentication();
  Timer? _autoLock;

  SecurityCubit(this.keyChain) : super(const SecurityState.initial()) {
    hydrate();
    _loadVerificationStatus();
    FGBGEvents.instance.stream.listen((FGBGType event) {
      final Duration lockInterval = state.lockInterval;
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

  Future<void> setPin(String pin) async {
    await keyChain.write(pinCodeKey, pin);
    emit(state.copyWith(pinStatus: PinStatus.enabled));
  }

  Future<bool> testPin(String pin) async {
    // Allow access if PIN is disabled
    if (state.pinStatus != PinStatus.enabled) {
      _setLockState(LockState.unlocked);
      _logger.info('PIN check bypassed: PIN is disabled');
      return true;
    }

    final String? storedPin = await keyChain.read(pinCodeKey);
    if (storedPin == null) {
      _logger.warning('PIN not found in storage but state indicates enabled');
      // Update both states and persist immediately
      await clearPin(); // Use existing method to ensure proper cleanup
      return true;
    }

    // Actual PIN comparison
    final bool matches = storedPin == pin;
    _logger.fine('PIN verification result: $matches');
    return matches;
  }

  Future<void> clearPin() async {
    emit(state.copyWith(pinStatus: PinStatus.disabled));
    await keyChain.delete(pinCodeKey);
    _setLockState(LockState.unlocked);
  }

  Future<void> setLockInterval(Duration lockInterval) async {
    emit(
      state.copyWith(
        lockInterval: lockInterval,
      ),
    );
    _setLockState(LockState.unlocked);
  }

  Future<void> clearLocalAuthentication() async {
    emit(
      state.copyWith(
        localAuthenticationOption: LocalAuthenticationOption.none,
      ),
    );
    _setLockState(LockState.unlocked);
  }

  Future<void> enableLocalAuthentication() async {
    emit(
      state.copyWith(
        localAuthenticationOption: await localAuthenticationOption(),
      ),
    );
    _setLockState(LockState.unlocked);
  }

  Future<LocalAuthenticationOption> localAuthenticationOption() async {
    final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
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
    final bool otherBiometrics = await _auth.isDeviceSupported();
    return otherBiometrics ? LocalAuthenticationOption.other : LocalAuthenticationOption.none;
  }

  Future<bool> localAuthentication(String localizedReason) async {
    try {
      final bool authenticated = await _auth.authenticate(
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: false,
        ),
        localizedReason: localizedReason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(),
          IOSAuthMessages(),
        ],
      );
      _setLockState(authenticated ? LockState.unlocked : LockState.locked);
      return authenticated;
    } on PlatformException catch (error) {
      if (error.code == 'LockedOut' || error.code == 'PermanentlyLockedOut') {
        throw error.message!;
      }
      _logger.severe('Error Code: ${error.code} - Message: ${error.message}', error);
      await _auth.stopAuthentication();
      _setLockState(LockState.locked);
      return false;
    }
  }

  void _setLockState(LockState lockState) {
    emit(state.copyWith(lockState: lockState));
  }

  Future<void> _loadVerificationStatus() async {
    final bool isVerified = await MnemonicVerificationStatusPreferences.isVerificationComplete();
    emit(
      state.copyWith(
        verificationStatus: isVerified ? VerificationStatus.verified : VerificationStatus.unverified,
      ),
    );
  }

  Future<void> verifyMnemonic() async {
    await MnemonicVerificationStatusPreferences.setVerificationComplete(true);
    await _loadVerificationStatus();
  }

  @override
  SecurityState? fromJson(Map<String, dynamic> json) {
    final SecurityState state = SecurityState.fromJson(json);
    // Only lock if PIN is enabled and not already in another lock state
    if (state.pinStatus == PinStatus.enabled && state.lockState != LockState.unlocked) {
      _setLockState(LockState.locked);
    } else {
      _setLockState(LockState.unlocked);
    }
    return state;
  }

  @override
  Map<String, dynamic>? toJson(SecurityState state) {
    return state.toJson();
  }
}

class SecurityStorageException implements Exception {}
