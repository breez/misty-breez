import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 2720);
  static const int frameCount = 67;

  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    )..forward(from: 0.0);

    _animation = IntTween(begin: 0, end: frameCount).animate(_controller);

    if (_controller.isCompleted) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        final int currentFrame = _animation.value;
        final String frame = currentFrame.toString().padLeft(2, '0');

        return Column(
          children: <Widget>[
            SizedBox(
              height: screenSize.height * 0.19,
              child: Image.asset(
                'assets/animations/welcome/frame_${frame}_delay-0.04s.png',
                gaplessPlayback: true,
                fit: BoxFit.cover,
              ),
            ),
            AnimatedOpacity(
              opacity: currentFrame >= 44 ? _controller.value : 0.0,
              duration: const Duration(milliseconds: 400),
              child: const TaglineText(),
            ),
          ],
        );
      },
    );
  }
}
