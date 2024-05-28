import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/bloc/security/security_bloc.dart';
import 'package:l_breez/bloc/security/security_state.dart';
import 'package:l_breez/widgets/designsystem/switch/simple_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocalAuthSwitch extends StatelessWidget {
  const LocalAuthSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final securityBloc = context.read<SecurityBloc>();

    return FutureBuilder<LocalAuthenticationOption>(
      future: securityBloc.localAuthenticationOption(),
      initialData: LocalAuthenticationOption.none,
      builder: (context, snapshot) {
        final availableOption = snapshot.data ?? LocalAuthenticationOption.none;
        if (availableOption == LocalAuthenticationOption.none) {
          return Container();
        } else {
          return BlocBuilder<SecurityBloc, SecurityState>(
            builder: (context, state) {
              final localAuthEnabled = state.localAuthenticationOption != LocalAuthenticationOption.none;
              return SimpleSwitch(
                text: _localAuthenticationOptionLabel(
                  context,
                  localAuthEnabled ? state.localAuthenticationOption : availableOption,
                ),
                switchValue: localAuthEnabled,
                onChanged: (value) => _localAuthenticationOptionChanged(context, value),
              );
            },
          );
        }
      },
    );
  }

  void _localAuthenticationOptionChanged(BuildContext context, bool switchEnabled) {
    final texts = context.texts();
    final securityBloc = context.read<SecurityBloc>();
    if (switchEnabled) {
      securityBloc.localAuthentication(texts.security_and_backup_validate_biometrics_reason).then(
        (authenticated) {
          if (authenticated) {
            securityBloc.enableLocalAuthentication();
          } else {
            securityBloc.clearLocalAuthentication();
          }
        },
        onError: (error) {
          securityBloc.clearLocalAuthentication();
        },
      );
    } else {
      securityBloc.clearLocalAuthentication();
    }
  }

  String _localAuthenticationOptionLabel(
    BuildContext context,
    LocalAuthenticationOption authenticationOption,
  ) {
    final texts = context.texts();
    switch (authenticationOption) {
      case LocalAuthenticationOption.face:
        return texts.security_and_backup_enable_biometric_option_face;
      case LocalAuthenticationOption.faceId:
        return texts.security_and_backup_enable_biometric_option_face_id;
      case LocalAuthenticationOption.fingerprint:
        return texts.security_and_backup_enable_biometric_option_fingerprint;
      case LocalAuthenticationOption.touchId:
        return texts.security_and_backup_enable_biometric_option_touch_id;
      case LocalAuthenticationOption.other:
        return texts.security_and_backup_enable_biometric_option_other;
      case LocalAuthenticationOption.none:
      default:
        return texts.security_and_backup_enable_biometric_option_none;
    }
  }
}
