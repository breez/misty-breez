import 'package:flutter/material.dart';
import 'package:l_breez/widgets/preview/preview.dart';

class DigitButtonWidget extends StatelessWidget {
  final String? digit;
  final IconData? icon;
  final Color? foregroundColor;
  final Function(String?)? onPressed;

  const DigitButtonWidget({
    super.key,
    this.digit,
    this.icon,
    this.foregroundColor = Colors.white,
    this.onPressed,
  }) : assert(digit != null || icon != null, "Either digit or icon must be provided");

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Center(
      child: InkWell(
        highlightColor: themeData.highlightColor,
        customBorder: const CircleBorder(),
        onTap: onPressed == null ? null : () => onPressed?.call(digit),
        child: Center(
          child: digit != null
              ? Text(
                  digit!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 20.0,
                  ),
                )
              : Icon(
                  icon,
                  color: foregroundColor,
                  size: 20.0,
                ),
        ),
      ),
    );
  }
}

void main() {
  runApp(
    Preview(
      List.generate(
        10,
        (index) => DigitButtonWidget(
          digit: "$index",
          onPressed: (digit) => debugPrint("Digit: $digit"),
        ),
      ),
    ),
  );
}
