import 'dart:math';

import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';
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
  final Random random = Random();
  final DateTime startTime = DateTime.now();
  final List<ParticleModel> particles = <ParticleModel>[];

  @override
  void initState() {
    super.initState();
    List<void>.generate(
      widget.numberOfParticles,
      (int index) {
        particles.add(ParticleModel(random));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoopAnimationBuilder<int>(
      duration: const Duration(seconds: 1),
      tween: ConstantTween<int>(1),
      builder: (BuildContext context, int animation, Widget? child) {
        final Duration time = DateTime.now().difference(startTime);
        _simulateParticles(time);
        return CustomPaint(
          painter: ParticlePainter(particles, time, widget.color),
        );
      },
    );
  }

  void _simulateParticles(Duration time) {
    for (ParticleModel particle in particles) {
      particle.maintainRestart(time);
    }
  }
}
