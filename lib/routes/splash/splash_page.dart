import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/routes/initial_walkthrough/initial_walkthrough.dart';
import 'package:l_breez/routes/splash/splash_animation_widget.dart';
import 'package:l_breez/theme/theme.dart';

class SplashPage extends StatefulWidget {
  static const routeName = "splash";

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
    final themeData = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: BreezColors.blue[500],
      ),
      child: Theme(
        data: breezLightTheme,
        child: const Scaffold(
          body: SplashAnimationWidget(),
        ),
      ),
    );
  }
}
