import 'dart:math';

import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/widgets/particle_animations/particle_model.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/widgets/particle_animations/particle_painter.dart';
import 'package:simple_animations/simple_animations.dart';

export 'animation_progress.dart';
export 'animation_properties.dart';
export 'particle_model.dart';
export 'particle_painter.dart';

class Particles extends StatefulWidget {
  final int numberOfParticles;
  final Color color;

  const Particles(this.numberOfParticles, {super.key, this.color = Colors.white});

  @override
  ParticlesState createState() => ParticlesState();
}

class ParticlesState extends State<Particles> {
  final random = Random();
  final startTime = DateTime.now();
  final List<ParticleModel> particles = [];

  @override
  void initState() {
    List.generate(widget.numberOfParticles, (index) {
      particles.add(ParticleModel(random));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LoopAnimationBuilder<int>(
      duration: const Duration(seconds: 1),
      tween: ConstantTween(1),
      builder: (context, animation, child) {
        final time = DateTime.now().difference(startTime);
        _simulateParticles(time);
        return CustomPaint(
          painter: ParticlePainter(particles, time, widget.color),
        );
      },
    );
  }

  void _simulateParticles(Duration time) {
    for (var particle in particles) {
      particle.maintainRestart(time);
    }
  }
}
