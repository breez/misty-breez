import 'dart:math';

import 'package:flutter/material.dart';

/// Controller for shake animation
class ShakeController {
  /// Animation controller for shake animation
  late final AnimationController _controller;

  /// Creates a shake controller
  ///
  /// [vsync] A ticker provider for animations
  ShakeController({required TickerProvider vsync}) {
    _controller = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 500));
  }

  /// The animation controller
  AnimationController get controller => _controller;

  /// Triggers a shake animation
  void shake() {
    _controller.forward(from: 0.0);
  }

  /// Disposes the controller
  void dispose() {
    _controller.dispose();
  }
}

/// Widget that shakes when triggered
class ShakeWidget extends StatelessWidget {
  /// The controller for the shake animation
  final ShakeController controller;

  /// The child widget
  final Widget child;

  /// Creates a shake widget
  ///
  /// [controller] Controls the shake animation
  /// [child] The widget to animate
  const ShakeWidget({required this.controller, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.controller,
      builder: (BuildContext context, Widget? child) {
        final double offset = sin(controller.controller.value * 10) * 10;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: child,
    );
  }
}
