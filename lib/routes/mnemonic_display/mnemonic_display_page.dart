import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/mnemonic_display/recovery_phrase_grid.dart';
import 'package:misty_breez/routes/mnemonic_display/warning_card.dart';
import 'package:misty_breez/theme/src/breez_light_theme.dart';
import 'package:misty_breez/widgets/error_dialog.dart';

class MnemonicDisplayPage extends StatelessWidget {
  final String mnemonic;
  const MnemonicDisplayPage({required this.mnemonic, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        final bool? shouldPop = await promptAreYouSure(
          context,
          title: texts.bootstrap_error_page_close_popup_title,
          body: Text(texts.bootstrap_error_page_close_popup_message),
        );
        if (shouldPop ?? false) {
          exit(0);
        }
      },
      child: MaterialApp(
        title: 'Misty ${getSystemAppLocalizations().app_name}',
        theme: breezLightTheme,
        localizationsDelegates: localizationsDelegates(),
        supportedLocales: supportedLocales(),
        builder: (BuildContext context, Widget? child) {
          const double kMaxTitleTextScaleFactor = 1.3;

          return MediaQuery.withClampedTextScaling(maxScaleFactor: kMaxTitleTextScaleFactor, child: child!);
        },
        home: Scaffold(
          appBar: AppBar(title: const Text('Recovery Phrase')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const WarningCard(
                title: 'Write This Down!',
                message:
                    'Please confirm that you have written down your recovery phrase. '
                    'This is essential for recovering your wallet if you lose access to your device.',
              ),
              const SizedBox(height: 24),
              RecoveryPhraseGrid(mnemonic: mnemonic),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
