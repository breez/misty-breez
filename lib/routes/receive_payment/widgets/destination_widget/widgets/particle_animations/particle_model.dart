import 'dart:math';

import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:simple_animations/simple_animations.dart';

class ParticleModel {
  Animatable<Movie>? tween;
  double? size;
  AnimationProgress? animationProgress;
  Random random;

  ParticleModel(this.random) {
    restart();
  }

  void restart({
    Duration time = Duration.zero,
  }) {
    final Offset startPosition = Offset(-0.2 + 1.4 * random.nextDouble(), 1.2);
    final Offset endPosition = Offset(-0.2 + 1.4 * random.nextDouble(), -0.2);
    final Duration duration = Duration(milliseconds: 3000 + random.nextInt(6000));

    tween = MovieTween()
      ..tween(
        AnimationProperties.X,
        Tween<double>(
          begin: startPosition.dx,
          end: endPosition.dx,
        ),
        duration: duration,
        curve: Curves.easeInOutSine,
      )
      ..tween(
        AnimationProperties.Y,
        Tween<double>(
          begin: startPosition.dy,
          end: endPosition.dy,
        ),
        duration: duration,
        curve: Curves.easeIn,
      );
    animationProgress = AnimationProgress(
      duration: duration,
      startTime: time,
    );
    size = 0.2 + random.nextDouble() * 0.4;
  }

  void maintainRestart(Duration time) {
    if (animationProgress!.progress(time) == 1.0) {
      restart(time: time);
    }
  }
}
