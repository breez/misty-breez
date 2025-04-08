import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;

/// A screen for managing security settings
class SecuritySettings extends StatelessWidget {
  /// Route name for navigation
  static const String routeName = '/security_settings';

  const SecuritySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        key: GlobalKey<ScaffoldState>(),
        leading: const back_button.BackButton(),
        title: Text(
          texts.security_and_backup_title,
          style: themeData.appBarTheme.toolbarTextStyle,
        ),
      ),
      body: ListView(
        children: const <Widget>[
          SecurityPinManagement(),
          Divider(),
          SecurityMnemonicsManagement(),
        ],
      ),
    );
  }
}
