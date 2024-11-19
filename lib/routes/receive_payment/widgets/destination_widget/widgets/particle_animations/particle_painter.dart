import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/widgets/particle_animations/animation_properties.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/widgets/particle_animations/particle_model.dart';
import 'package:simple_animations/simple_animations.dart';

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final Duration time;
  final Color color;

  const ParticlePainter(
    this.particles,
    this.time,
    this.color,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color.withAlpha(150);

    for (ParticleModel particle in particles) {
      final double progress = particle.animationProgress!.progress(time);
      final Movie animation = particle.tween!.transform(progress);
      final Offset position = Offset(
        animation.get(AnimationProperties.X) * size.width,
        animation.get(AnimationProperties.Y) * size.height,
      );
      canvas.drawCircle(
        position,
        size.width * 0.2 * particle.size!,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
