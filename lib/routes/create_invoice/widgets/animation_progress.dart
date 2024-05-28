import 'dart:math';

class AnimationProgress {
  final Duration duration;
  final Duration startTime;

  const AnimationProgress({
    required this.duration,
    required this.startTime,
  });

  double progress(Duration time) => max(
        0.0,
        min((time - startTime).inMilliseconds / duration.inMilliseconds, 1.0),
      );
}
