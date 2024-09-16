import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';

class SuccessfulPaymentRoute extends StatefulWidget {
  const SuccessfulPaymentRoute({super.key});

  @override
  State<StatefulWidget> createState() => SuccessfulPaymentRouteState();
}

class SuccessfulPaymentRouteState extends State<SuccessfulPaymentRoute> with TickerProviderStateMixin {
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  late AnimationController _particlesController;
  late Animation<double> _particlesFadeAnimation;
  bool showParticles = false;

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimationController.forward();

    _particlesController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _particlesFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _particlesController,
        curve: Curves.easeInCubic,
      ),
    );

    _slideAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          _slideAnimationController.reverse();
        });
      }
      if (status == AnimationStatus.reverse) {
        Future.delayed(const Duration(milliseconds: 400), () {
          setState(() {
            showParticles = true;
          });
          _particlesController.forward();
        });
      }
    });

    _particlesController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Stack(
      children: [
        if (!showParticles)
          SlideTransition(
            position: _slideAnimation, // Apply the slide animation
            child: Container(
              color: themeData.bottomAppBarTheme.color
                  ?.withOpacity(0.95), // Fullscreen half-transparent background
              child: const Center(
                child: SuccessfulPaymentMessage(), // The message widget
              ),
            ),
          ),
        if (showParticles)
          Positioned.fill(
            child: FadeTransition(
              opacity: _particlesFadeAnimation,
              child: Particles(
                50,
                color: Colors.blue.withAlpha(150),
              ),
            ),
          ),
      ],
    );
  }
}
