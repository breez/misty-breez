import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SecurityPinManagement');

/// Widget for managing PIN security settings
class SecurityPinManagement extends StatelessWidget {
  /// Creates a security PIN management widget
  const SecurityPinManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (BuildContext context, SecurityState state) {
        final BreezTranslations texts = context.texts();
        final ThemeData themeData = Theme.of(context);
        final NavigatorState navigator = Navigator.of(context);
        final AuthService authService = AuthService(context: context);

        return authService.isPinEnabled
            ? _buildEnabledPinOptions(context, authService, texts, themeData, navigator, state)
            : _buildCreatePinOption(texts, themeData, navigator);
      },
    );
  }
}

/// Builds the UI for when PIN protection is enabled
Widget _buildEnabledPinOptions(
  BuildContext context,
  AuthService authService,
  BreezTranslations texts,
  ThemeData themeData,
  NavigatorState navigator,
  SecurityState state,
) {
  return Column(
    children: <Widget>[
      _buildDisablePinSwitch(authService, texts),
      const Divider(),
      AutoLockTimeout(interval: state.autoLockTimeout),
      const Divider(),
      _buildChangePinTile(texts, themeData, navigator),
      const Divider(),
      const LocalAuthSwitch(),
    ],
  );
}

/// Builds the switch to disable PIN protection
Widget _buildDisablePinSwitch(
  AuthService authService,
  BreezTranslations texts,
) {
  return SimpleSwitch(
    text: texts.security_and_backup_pin_option_deactivate,
    switchValue: true,
    onChanged: (bool value) {
      if (!value) {
        _logger.info('Disabling PIN protection');
        authService.disablePin();
      }
    },
  );
}

/// Builds the tile to change the PIN
Widget _buildChangePinTile(
  BreezTranslations texts,
  ThemeData themeData,
  NavigatorState navigator,
) {
  return ListTile(
    title: Text(
      texts.security_and_backup_change_pin,
      style: themeData.primaryTextTheme.titleMedium?.copyWith(
        color: Colors.white,
      ),
      maxLines: 1,
    ),
    trailing: const Icon(
      Icons.keyboard_arrow_right,
      color: Colors.white,
      size: 30.0,
    ),
    onTap: () {
      _logger.info('Navigating to change PIN page');
      navigator.push(
        FadeInRoute<void>(
          builder: (_) => const ChangePinPage(),
        ),
      );
    },
  );
}

/// Builds the option to create a PIN when none exists
Widget _buildCreatePinOption(
  BreezTranslations texts,
  ThemeData themeData,
  NavigatorState navigator,
) {
  return ListTile(
    title: Text(
      texts.security_and_backup_pin_option_create,
      style: themeData.primaryTextTheme.titleMedium?.copyWith(
        color: Colors.white,
      ),
      maxLines: 1,
    ),
    trailing: const Icon(
      Icons.keyboard_arrow_right,
      color: Colors.white,
      size: 30.0,
    ),
    onTap: () {
      _logger.info('Navigating to create PIN page');
      navigator.push(
        FadeInRoute<void>(
          builder: (_) => const ChangePinPage(),
        ),
      );
    },
  );
}
