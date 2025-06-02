import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('LocalAuthSwitch');

/// A widget for toggling biometric authentication
class LocalAuthSwitch extends StatelessWidget {
  /// Creates a local authentication switch
  const LocalAuthSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(context: context);

    return FutureBuilder<BiometricType>(
      future: authService.detectBiometricType(),
      initialData: BiometricType.none,
      builder: (BuildContext context, AsyncSnapshot<BiometricType> snapshot) {
        final BiometricType availableOption = snapshot.data ?? BiometricType.none;

        if (availableOption == BiometricType.none) {
          _logger.info('No biometric authentication options available');
          return const SizedBox.shrink();
        }

        return _buildBiometricSwitch(context, availableOption);
      },
    );
  }

  /// Builds the biometric toggle switch
  Widget _buildBiometricSwitch(BuildContext context, BiometricType availableOption) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (BuildContext context, SecurityState state) {
        final bool localAuthEnabled = state.biometricType != BiometricType.none;

        return SimpleSwitch(
          text: _getBiometricTypeLabel(context, localAuthEnabled ? state.biometricType : availableOption),
          switchValue: localAuthEnabled,
          onChanged: (bool value) => _onBiometricToggled(context, value),
        );
      },
    );
  }

  /// Handles toggling biometric authentication
  void _onBiometricToggled(BuildContext context, bool switchEnabled) {
    final AuthService authService = AuthService(context: context);

    if (switchEnabled) {
      _logger.info('Attempting to enable biometric authentication');

      authService
          .authenticateWithBiometrics(updateLockStateOnFailure: false)
          .then(
            (AuthResult authResult) {
              if (authResult.success) {
                _logger.info('Biometric authentication successful, enabling');
                authService.enableBiometricAuth();
              } else {
                _logger.warning('Biometric authentication failed, not enabling');
                _logger.warning('Reason: ${authResult.errorMessage}');
                authService.disableBiometricAuth();
              }
            },
            onError: (Object error) {
              _logger.severe('Error during biometric authentication: $error');
              authService.disableBiometricAuth();
              if (context.mounted) {
                showFlushbar(context, message: ExceptionHandler.extractMessage(error, context.texts()));
              }
            },
          );
    } else {
      _logger.info('Disabling biometric authentication');
      authService.disableBiometricAuth();
    }
  }

  /// Gets a human-readable label for the biometric type
  String _getBiometricTypeLabel(BuildContext context, BiometricType authenticationOption) {
    final BreezTranslations texts = context.texts();

    switch (authenticationOption) {
      case BiometricType.face:
        return texts.security_and_backup_enable_biometric_option_face;
      case BiometricType.faceId:
        return texts.security_and_backup_enable_biometric_option_face_id;
      case BiometricType.fingerprint:
        return texts.security_and_backup_enable_biometric_option_fingerprint;
      case BiometricType.touchId:
        return texts.security_and_backup_enable_biometric_option_touch_id;
      case BiometricType.other:
        return texts.security_and_backup_enable_biometric_option_other;
      case BiometricType.none:
        return texts.security_and_backup_enable_biometric_option_none;
    }
  }
}
