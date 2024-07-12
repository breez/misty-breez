import 'package:flutter/material.dart';

class SplashAnimationWidget extends StatelessWidget {
  const SplashAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'src/images/splash-animation.gif',
        fit: BoxFit.contain,
        gaplessPlayback: true,
        width: MediaQuery.of(context).size.width / 3,
      ),
    );
  }
}
