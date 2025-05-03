import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:provider/provider.dart';

class RestoreButton extends StatelessWidget {
  final AutoSizeGroup autoSizeGroup;

  const RestoreButton({required this.autoSizeGroup, super.key});

  @override
  Widget build(BuildContext context) {
    final InitialWalkthroughService walkthroughService = Provider.of<InitialWalkthroughService>(
      context,
      listen: false,
    );

    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: 48.0,
      width: min(screenSize.width * 0.5, 168),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white),
          elevation: 0.0,
          disabledBackgroundColor: themeData.disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: walkthroughService.restoreWallet,
        child: Semantics(
          button: true,
          // TODO(erdemyerebasmaz): Add message to Breez-Translations
          label: 'Restore using mnemonics',
          child: AutoSizeText(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            'RESTORE',
            style: themeData.textTheme.labelLarge?.copyWith(
              color: Colors.white,
            ),
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
