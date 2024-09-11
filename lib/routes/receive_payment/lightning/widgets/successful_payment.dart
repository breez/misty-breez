import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/particle_animations/particles_animations.dart';

class SuccessfulPaymentRoute extends StatefulWidget {
  const SuccessfulPaymentRoute({super.key});

  @override
  State<StatefulWidget> createState() => SuccessfulPaymentRouteState();
}

class SuccessfulPaymentRouteState extends State<SuccessfulPaymentRoute> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.forward().then((_) {
          Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Stack(
        children: [
          Positioned.fill(
            child: Particles(
              50,
              color: Colors.blue.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
