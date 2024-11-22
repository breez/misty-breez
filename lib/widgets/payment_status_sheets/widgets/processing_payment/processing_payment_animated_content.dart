import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';

class ProcessingPaymentAnimatedContent extends StatelessWidget {
  final Color color;
  final double opacity;
  final double moment;
  final double border;
  final double startHeight;
  final Animation<RelativeRect> transitionAnimation;
  final Widget child;

  const ProcessingPaymentAnimatedContent({
    required this.color,
    required this.opacity,
    required this.moment,
    required this.border,
    required this.startHeight,
    required this.transitionAnimation,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final MediaQueryData queryData = MediaQuery.of(context);

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            PositionedTransition(
              rect: transitionAnimation,
              child: Container(
                height: startHeight,
                width: queryData.size.width,
                decoration: ShapeDecoration(
                  color: themeData.isLightTheme
                      ? color
                      : moment >= 0.25
                          ? themeData.colorScheme.surface
                          : color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      border,
                    ),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
