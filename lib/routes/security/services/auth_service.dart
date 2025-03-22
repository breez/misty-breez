import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/security/models/auth_result.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('AuthService');

/// Service class for handling authentication-related operations
class AuthService {
  /// The BuildContext for localization and accessing providers
  final BuildContext context;

  /// Creates an AuthService instance
  ///
  /// [context] The BuildContext for accessing dependencies
  AuthService({required this.context});

  /// Gets the current security state
  SecurityState get _securityState => context.read<SecurityCubit>().state;

  /// Gets the security cubit
  SecurityCubit get _securityCubit => context.read<SecurityCubit>();

  /// Gets translations for the current locale
  BreezTranslations get _texts => context.texts();

  /// Gets the current biometric type from security state
  BiometricType get biometricType => _securityState.biometricType;

  /// Checks if PIN protection is enabled
  bool get isPinEnabled => _securityState.pinStatus == PinStatus.enabled;

  /// Validates a PIN code
  ///
  /// [pin] PIN code to validate
  /// Returns an [AuthResult] with the validation outcome
  Future<AuthResult> validatePin(String pin) async {
    _logger.fine('Validating PIN');

    try {
      final bool isValid = await _securityCubit.validatePin(pin);

      if (isValid) {
        _logger.fine('PIN validated successfully');
        return const AuthResult(success: true);
      }

      _logger.warning('PIN validation failed: incorrect PIN');
      return AuthResult(
        success: false,
        errorMessage: _texts.lock_screen_pin_incorrect,
      );
    } catch (e) {
      _logger.severe('PIN validation error: $e');
      return AuthResult(
        success: false,
        errorMessage: _texts.lock_screen_pin_match_exception,
      );
    }
  }

  /// Authenticates using biometrics
  ///
  /// Returns an [AuthResult] with the authentication outcome
  Future<AuthResult> authenticateWithBiometrics() async {
    _logger.fine('Attempting biometric authentication');

    try {
      final bool isValid = await _securityCubit.authenticateWithBiometrics(
        _texts.security_and_backup_validate_biometrics_reason,
      );

      if (isValid) {
        _logger.fine('Biometric authentication succeeded');
        return const AuthResult(success: true);
      }

      _logger.warning('Biometric authentication failed');
      return AuthResult(
        success: false,
        errorMessage: _texts.lock_screen_pin_incorrect,
      );
    } catch (e) {
      _logger.severe('Biometric authentication error: $e');
      return AuthResult(
        success: false,
        errorMessage: _texts.lock_screen_pin_match_exception,
      );
    }
  }

  /// Creates or updates the PIN code
  ///
  /// [pin] The new PIN code to set
  /// Returns true if successful, false otherwise
  Future<bool> createOrUpdatePin(String pin) async {
    try {
      await _securityCubit.createOrUpdatePin(pin);
      _logger.info('PIN created/updated successfully');
      return true;
    } catch (e) {
      _logger.severe('Error creating/updating PIN: $e');
      return false;
    }
  }

  /// Disables PIN protection
  Future<void> disablePin() async {
    await _securityCubit.disablePin();
    _logger.info('PIN protection disabled');
  }

  /// Updates the auto-lock timeout
  ///
  /// [duration] The new timeout duration
  Future<void> updateAutoLockTimeout(Duration duration) async {
    await _securityCubit.updateAutoLockTimeout(duration);
    _logger.info('Auto-lock timeout updated to ${duration.inSeconds} seconds');
  }

  /// Detects available biometric authentication types
  Future<BiometricType> detectBiometricType() async {
    return _securityCubit.detectBiometricType();
  }

  /// Enables biometric authentication
  Future<void> enableBiometricAuth() async {
    await _securityCubit.enableBiometricAuth();
    _logger.info('Biometric authentication enabled');
  }

  /// Disables biometric authentication
  Future<void> disableBiometricAuth() async {
    await _securityCubit.disableBiometricAuth();
    _logger.info('Biometric authentication disabled');
  }
}
