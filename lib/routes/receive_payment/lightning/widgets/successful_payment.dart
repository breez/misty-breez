import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/particle_animations/particles_animations.dart';

class SuccessfulPaymentRoute extends StatefulWidget {
  const SuccessfulPaymentRoute({super.key});

  @override
  State<StatefulWidget> createState() => SuccessfulPaymentRouteState();
}

class SuccessfulPaymentRouteState extends State<SuccessfulPaymentRoute> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Particles(
            50,
            color: Colors.blue.withAlpha(150),
          ),
        ),
      ],
    );
  }
}
