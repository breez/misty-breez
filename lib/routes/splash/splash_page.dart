import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';

class SplashPage extends StatefulWidget {
  static const String routeName = 'splash';

  const SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 3600), () {
      Navigator.of(context).pushReplacementNamed(InitialWalkthroughPage.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: BreezColors.blue[500],
      ),
      child: Theme(
        data: breezLightTheme,
        child: Scaffold(
          body: Center(
            child: Image.asset(
              'assets/animations/splash-animation.gif',
              fit: BoxFit.contain,
              gaplessPlayback: true,
              width: MediaQuery.of(context).size.width / 3,
            ),
          ),
        ),
      ),
    );
  }
}
