import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:keychain/keychain.dart';
import 'package:local_auth/local_auth.dart' as l_auth;
import 'package:local_auth_android/local_auth_android.dart' as l_auth_android;
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'mnemonic_verification_status_preferences.dart';
export 'security_state.dart';

final Logger _logger = Logger('SecurityCubit');

/// Key used to store PIN code in secure storage
const String _pinCodeKeyName = 'pinCode';

/// Manages app security features including PIN protection, biometric authentication,
/// automatic locking, and mnemonic verification status.
class SecurityCubit extends Cubit<SecurityState> with HydratedMixin<SecurityState> {
  /// Secure storage for sensitive data like PIN code
  final KeyChain _keyChain;

  /// Authentication service for biometric verification
  final l_auth.LocalAuthentication _auth = l_auth.LocalAuthentication();

  /// Timer for automatic locking when app goes to background
  Timer? _autoLockTimer;

  /// Creates a SecurityCubit instance and initializes security state
  ///
  /// [_keyChain] Secure storage implementation for sensitive data
  SecurityCubit(this._keyChain) : super(const SecurityState.initial()) {
    hydrate();

    _initializeSecurityState();
  }

  /// Initializes the security state by loading verification status and setting up
  /// background lock listeners
  Future<void> _initializeSecurityState() async {
    await _loadMnemonicVerificationStatus();
    _setupBackgroundLockListener();
  }

  /// Sets up the app background/foreground listener to manage auto-locking
  void _setupBackgroundLockListener() {
    FGBGEvents.instance.stream.listen(_handleAppStateChange);
  }

  /// Handles app state changes between foreground and background
  ///
  /// [event] The foreground/background state change event
  void _handleAppStateChange(FGBGType event) {
    if (event == FGBGType.foreground) {
      _cancelAutoLockTimer();
    } else {
      _startAutoLockTimerIfNeeded();
    }
  }

  /// Cancels any active auto-lock timer
  void _cancelAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  /// Starts the auto-lock timer if PIN protection is enabled
  void _startAutoLockTimerIfNeeded() {
    if (state.pinStatus == PinStatus.enabled) {
      _autoLockTimer = Timer(state.autoLockTimeout, () {
        _updateLockState(LockState.locked);
        _autoLockTimer = null;
        _logger.info('App automatically locked due to inactivity');
      });
    }
  }

  /// Creates or updates the PIN for app security
  ///
  /// [pin] The new PIN code to set
  ///
  /// Throws [Exception] if the PIN cannot be stored securely
  Future<void> createOrUpdatePin(String pin) async {
    try {
      await _keyChain.write(_pinCodeKeyName, pin);
      emit(state.copyWith(pinStatus: PinStatus.enabled));
      _logger.info('PIN code has been updated');
    } catch (e) {
      _logger.severe('Failed to save PIN code: $e');
      throw Exception('Failed to save PIN code: $e');
    }
  }

  /// Validates if the provided PIN matches the stored PIN
  ///
  /// [pin] The PIN code to validate
  ///
  /// Returns true if the PIN is valid, false otherwise
  ///
  /// Throws [Exception] if the PIN is not found in secure storage
  Future<bool> validatePin(String pin) async {
    try {
      final String? storedPin = await _keyChain.read(_pinCodeKeyName);
      if (storedPin == null) {
        _logger.warning('PIN not found in secure storage. Disabling PIN.');
        await disablePin();
        throw Exception('PIN not found in secure storage. Disabling PIN.');
      }

      final bool isValid = storedPin == pin;
      if (isValid) {
        _updateLockState(LockState.unlocked);
      }

      return isValid;
    } catch (e) {
      _logger.severe('Error validating PIN: $e');
      rethrow;
    }
  }

  /// Disables PIN protection by removing the stored PIN
  Future<void> disablePin() async {
    try {
      emit(state.copyWith(pinStatus: PinStatus.disabled));
      await _keyChain.delete(_pinCodeKeyName);
      _updateLockState(LockState.unlocked);
      _logger.info('PIN protection disabled');
    } catch (e) {
      _logger.severe('Failed to disable PIN: $e');
      throw Exception('Failed to disable PIN: $e');
    }
  }

  /// Updates the auto-lock timeout interval
  ///
  /// [autoLockTimeout] The new timeout duration
  Future<void> updateAutoLockTimeout(Duration autoLockTimeout) async {
    emit(state.copyWith(autoLockTimeout: autoLockTimeout));
    _updateLockState(LockState.unlocked);
    _logger.info('Auto-lock timeout updated to ${autoLockTimeout.inSeconds} seconds');
  }

  /// Disables biometric authentication
  Future<void> disableBiometricAuth() async {
    emit(state.copyWith(biometricType: BiometricType.none));
    _updateLockState(LockState.unlocked);
    _logger.info('Biometric authentication disabled');
  }

  /// Enables biometric authentication if supported by the device
  Future<void> enableBiometricAuth() async {
    final BiometricType detectedType = await detectBiometricType();
    emit(state.copyWith(biometricType: detectedType));
    _updateLockState(LockState.unlocked);

    if (detectedType != BiometricType.none) {
      _logger.info('Biometric authentication enabled: ${detectedType.name}');
    } else {
      _logger.warning('No biometric capabilities detected on device');
    }
  }

  /// Detects what type of biometric authentication is available on the device
  ///
  /// Returns the detected [BiometricType]
  Future<BiometricType> detectBiometricType() async {
    try {
      final List<l_auth.BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      _logger.info('Available biometrics: $availableBiometrics');

      if (availableBiometrics.contains(l_auth.BiometricType.face)) {
        return defaultTargetPlatform == TargetPlatform.iOS ? BiometricType.faceId : BiometricType.face;
      }

      if (availableBiometrics.contains(l_auth.BiometricType.fingerprint)) {
        return defaultTargetPlatform == TargetPlatform.iOS
            ? BiometricType.touchId
            : BiometricType.fingerprint;
      }

      final bool otherBiometrics = await _auth.isDeviceSupported();
      return otherBiometrics ? BiometricType.other : BiometricType.none;
    } catch (e) {
      _logger.severe('Error detecting biometric type: $e');
      return BiometricType.none;
    }
  }

  /// Attempts to authenticate the user using device biometrics
  ///
  /// [localizedReason] Reason for authentication displayed to user
  ///
  /// Returns true if authentication succeeded, false otherwise
  Future<bool> authenticateWithBiometrics(
    String localizedReason, {
    bool updateLockStateOnFailure = true,
  }) async {
    final BiometricType detectedType = await detectBiometricType();
    if (detectedType == BiometricType.none) {
      _logger.warning('Attempted biometric authentication when not available');
      return false;
    }

    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const l_auth.AuthenticationOptions(biometricOnly: true, useErrorDialogs: false),
        authMessages: const <l_auth_android.AuthMessages>[
          l_auth_android.AndroidAuthMessages(),
          IOSAuthMessages(),
        ],
      );

      if (authenticated || updateLockStateOnFailure) {
        _updateLockState(authenticated ? LockState.unlocked : LockState.locked);
      }
      _logger.info('Biometric authentication ${authenticated ? 'succeeded' : 'failed'}');
      return authenticated;
    } on PlatformException catch (error) {
      if (error.code == 'LockedOut' || error.code == 'PermanentlyLockedOut') {
        _logger.warning('Biometric authentication locked out: ${error.message}');
        throw error.message!;
      }

      _logger.severe('Biometric error: ${error.code} - ${error.message}', error);
      await _auth.stopAuthentication();
      if (updateLockStateOnFailure) {
        _updateLockState(LockState.locked);
      }
      throw '${error.code} - ${error.message}';
    } catch (e) {
      _logger.severe('Unexpected error during biometric authentication: $e');
      if (updateLockStateOnFailure) {
        _updateLockState(LockState.locked);
      }
      rethrow;
    }
  }

  /// Updates the app lock state
  ///
  /// [lockState] The new lock state to set
  void _updateLockState(LockState lockState) {
    if (state.lockState != lockState) {
      emit(state.copyWith(lockState: lockState));
      _logger.fine('Lock state updated to: ${lockState.name}');
    }
  }

  /// Loads the mnemonic verification status from preferences
  Future<void> _loadMnemonicVerificationStatus() async {
    try {
      final bool isVerified = await MnemonicVerificationStatusPreferences.isVerificationComplete();
      emit(state.copyWith(mnemonicStatus: isVerified ? MnemonicStatus.verified : MnemonicStatus.unverified));
      _logger.info('Mnemonic verification status loaded: ${isVerified ? 'verified' : 'unverified'}');
    } catch (e) {
      _logger.severe('Error loading mnemonic verification status: $e');
      // Keep default unverified status on error
    }
  }

  /// Marks the mnemonic as verified by the user
  Future<void> completeMnemonicVerification() async {
    try {
      await MnemonicVerificationStatusPreferences.setVerificationComplete(true);
      await _loadMnemonicVerificationStatus();
      _logger.info('Mnemonic verification completed');
    } catch (e) {
      _logger.severe('Error completing mnemonic verification: $e');
      throw Exception('Failed to save mnemonic verification status: $e');
    }
  }

  @override
  SecurityState? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.severe('No stored data found.');
      return null;
    }

    try {
      final SecurityState result = SecurityState.fromJson(json);
      _logger.fine('Successfully hydrated with $result');

      // Update lock state based on PIN status
      _updateLockState(result.pinStatus == PinStatus.enabled ? LockState.locked : LockState.unlocked);

      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error hydrating: $e');
      _logger.fine('Stack trace: $stackTrace');
      return const SecurityState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(SecurityState state) {
    try {
      final Map<String, dynamic> result = state.toJson();
      _logger.fine('Serialized: $result');
      return result;
    } catch (e) {
      _logger.severe('Error serializing: $e');
      return null;
    }
  }

  @override
  String get storagePrefix => defaultTargetPlatform == TargetPlatform.iOS ? 'SWa' : 'SecurityCubit';

  @override
  Future<void> close() {
    _cancelAutoLockTimer();
    return super.close();
  }
}
