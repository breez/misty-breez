import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/routes/splash/splash_animation_widget.dart';
import 'package:l_breez/theme/theme_provider.dart';

class SplashPage extends StatefulWidget {
  final bool isInitial;

  const SplashPage({super.key, required this.isInitial});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    if (widget.isInitial) {
      Timer(const Duration(milliseconds: 3600), () {
        Navigator.of(context).pushReplacementNamed('/intro');
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
    }
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
        child: Scaffold(
          body: widget.isInitial ? const SplashAnimationWidget() : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
