import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/receive_payment.dart';

export 'successful_payment_message.dart';

class SuccessfulPaymentRoute extends StatefulWidget {
  final bool particlesEnabled;

  const SuccessfulPaymentRoute({super.key, this.particlesEnabled = true});

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

    _slideAnimationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          _slideAnimationController.reverse();
        });
      }
      if (status == AnimationStatus.reverse) {
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          setState(() {
            showParticles = widget.particlesEnabled;
          });
          _particlesController.forward();
        });
      }
    });

    _particlesController.addStatusListener((AnimationStatus status) {
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
    final ThemeData themeData = Theme.of(context);
    return Stack(
      children: <Widget>[
        if (!showParticles)
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              color: themeData.bottomAppBarTheme.color?.withOpacity(0.98),
              child: const Center(
                child: SuccessfulPaymentMessage(),
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
