import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/home.dart';
import 'package:l_breez/routes/security/widget/pin_code_widget.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:nested/nested.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ServiceInjector injector = ServiceInjector();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: Directory(
      join((await getApplicationDocumentsDirectory()).path, 'preview_storage'),
    ),
  );
  runApp(
    MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<SecurityCubit>(
          create: (BuildContext context) => SecurityCubit(injector.keychain),
        ),
      ],
      child: MaterialApp(
        theme: breezLightTheme,
        home: LayoutBuilder(
          builder: (BuildContext context, _) => Center(
            child: TextButton(
              child: const Text('Launch lock screen'),
              onPressed: () => Navigator.of(context).push(
                FadeInRoute<void>(
                  builder: (_) => const LockScreen(
                    authorizedAction: AuthorizedAction.popPage,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
