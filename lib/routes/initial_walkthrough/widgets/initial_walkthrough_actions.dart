import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:provider/provider.dart';

class InitialWalkthroughActions extends StatelessWidget {
  const InitialWalkthroughActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<InitialWalkthroughService>(
      create: (BuildContext context) => InitialWalkthroughService(context),
      lazy: false,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RegisterButton(),
          SizedBox(height: 24),
          RestoreButton(),
        ],
      ),
    );
  }
}
