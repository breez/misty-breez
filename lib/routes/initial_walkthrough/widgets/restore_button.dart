import 'dart:math';

import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:provider/provider.dart';

class RestoreButton extends StatelessWidget {
  const RestoreButton({super.key});

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
      width: min(screenSize.width * 0.4, 168),
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
          child: Text(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            'RESTORE',
            style: themeData.textTheme.labelLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
