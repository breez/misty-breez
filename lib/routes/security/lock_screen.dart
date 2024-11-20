import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';

class LockScreen extends StatelessWidget {
  final AuthorizedAction authorizedAction;

  static const String routeName = 'lockscreen';

  const LockScreen({required this.authorizedAction, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final NavigatorState navigator = Navigator.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: BlocBuilder<SecurityCubit, SecurityState>(
          builder: (BuildContext context, SecurityState state) {
            return PinCodeWidget(
              label: texts.lock_screen_enter_pin,
              localAuthenticationOption: state.localAuthenticationOption,
              testPinCodeFunction: (String pin) async {
                bool pinMatches = false;
                try {
                  final SecurityCubit securityCubit = context.read<SecurityCubit>();
                  pinMatches = await securityCubit.testPin(pin);
                } catch (e) {
                  return TestPinResult(
                    false,
                    errorMessage: texts.lock_screen_pin_match_exception,
                  );
                }
                if (pinMatches) {
                  _authorized(navigator);
                  return const TestPinResult(true);
                } else {
                  return TestPinResult(
                    false,
                    errorMessage: texts.lock_screen_pin_incorrect,
                  );
                }
              },
              testBiometricsFunction: () async {
                final SecurityCubit securityCubit = context.read<SecurityCubit>();
                final bool pinMatches = await securityCubit.localAuthentication(
                  texts.security_and_backup_validate_biometrics_reason,
                );
                if (pinMatches) {
                  _authorized(navigator);
                  return const TestPinResult(true);
                } else {
                  return TestPinResult(
                    false,
                    errorMessage: texts.lock_screen_pin_incorrect,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _authorized(NavigatorState navigator) {
    switch (authorizedAction) {
      case AuthorizedAction.launchHome:
        navigator.pushReplacementNamed(Home.routeName);
        break;
      case AuthorizedAction.popPage:
        navigator.pop(true);
        break;
    }
  }
}

enum AuthorizedAction {
  launchHome,
  popPage,
}
