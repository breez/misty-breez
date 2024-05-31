import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

// Based on https://github.com/FayaPay/flutter-shake-anim/blob/master/lib/ui/shake_view.dart
class ShakeWidget extends StatelessWidget {
  final ShakeController controller;
  final Animation _anim;
  final Widget child;

  ShakeWidget({
    super.key,
    required this.controller,
    required this.child,
  }) : _anim = Tween<double>(begin: 50, end: 120).animate(controller);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) => Transform(
        transform: Matrix4.translation(_shake(_anim.value)),
        child: child,
      ),
    );
  }

  Vector3 _shake(double progress) {
    double offset = sin(progress * pi * 4.0);
    return Vector3(offset * 4, 0.0, 0.0);
  }
}

class ShakeController extends AnimationController {
  ShakeController(
    TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 300),
  }) : super(vsync: vsync, duration: duration);

  void shake() async {
    if (status == AnimationStatus.completed) {
      await reverse();
    } else {
      await forward();
    }
  }
}
