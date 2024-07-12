import 'dart:math';

import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;

class FlipTransition extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final double radius;
  final Function() onComplete;

  const FlipTransition(
    this.firstChild,
    this.secondChild, {
    super.key,
    required this.radius,
    required this.onComplete,
  });

  @override
  State<StatefulWidget> createState() => FlipTransitionState();
}

class FlipTransitionState extends State<FlipTransition> with TickerProviderStateMixin {
  AnimationController? _flipAnimationController;
  Animation? _flipAnimation;
  static const flipDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _flipAnimationController = AnimationController(vsync: this, duration: flipDuration);
    _flipAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipAnimationController!,
        curve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _flipAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flipAnimationController!.reverse();
      }
    });
    _flipAnimationController!.forward().whenCompleteOrCancel(() {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _flipAnimationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: Theme.of(context).customData.paymentListBgColor,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: Transform(
              transform: Matrix4.identity()..rotateY(pi * _flipAnimation!.value),
              alignment: Alignment.center,
              child: _flipAnimationController!.value >= 0.4 ? widget.secondChild : widget.firstChild,
            ),
          ),
        );
      },
    );
  }
}
