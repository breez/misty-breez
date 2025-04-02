import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:provider/provider.dart';

final AutoSizeGroup _autoSizeGroup = AutoSizeGroup();

class InitialWalkthroughActions extends StatelessWidget {
  const InitialWalkthroughActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<InitialWalkthroughService>(
      create: (BuildContext context) => InitialWalkthroughService(context),
      lazy: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RegisterButton(autoSizeGroup: _autoSizeGroup),
          const SizedBox(height: 24),
          RestoreButton(autoSizeGroup: _autoSizeGroup),
        ],
      ),
    );
  }
}
