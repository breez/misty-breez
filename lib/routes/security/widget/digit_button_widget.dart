import 'package:flutter/material.dart';
import 'package:l_breez/widgets/widgets.dart';

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
  }) : assert(digit != null || icon != null, 'Either digit or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

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
      List<Widget>.generate(
        10,
        (int index) => DigitButtonWidget(
          digit: '$index',
          onPressed: (String? digit) => debugPrint('Digit: $digit'),
        ),
      ),
    ),
  );
}
