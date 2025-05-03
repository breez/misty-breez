import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:provider/provider.dart';

class RegisterButton extends StatelessWidget {
  final AutoSizeGroup autoSizeGroup;

  const RegisterButton({required this.autoSizeGroup, super.key});

  @override
  Widget build(BuildContext context) {
    final InitialWalkthroughService walkthroughService = Provider.of<InitialWalkthroughService>(
      context,
      listen: false,
    );

    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: 48.0,
      width: min(screenSize.width * 0.5, 168),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeData.primaryColor,
          elevation: 0.0,
          disabledBackgroundColor: themeData.disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: walkthroughService.registerWallet,
        child: Semantics(
          button: true,
          // TODO(erdemyerebasmaz): Add message to Breez-Translations
          label: 'Start using Breez',
          child: AutoSizeText(
            texts.initial_walk_through_lets_breeze,
            style: themeData.textTheme.labelLarge,
            minFontSize: MinFontSize(context).minFontSize,
            stepGranularity: 0.1,
            group: autoSizeGroup,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
