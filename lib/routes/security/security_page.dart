import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/security/widget/mnemonics/security_mnemonics_management.dart';
import 'package:l_breez/routes/security/widget/security_pin_management.dart';
import 'package:l_breez/theme/breez_light_theme.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

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
        children: const [
          SecurityPinManagement(),
          Divider(),
          SecurityMnemonicsManagement(),
        ],
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      theme: breezLightTheme,
      home: const SecurityPage(),
    ),
  );
}
