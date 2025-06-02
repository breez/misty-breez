import 'package:flutter/material.dart';

/// A button widget for displaying digits or icons in a number pad.
class DigitButton extends StatelessWidget {
  /// The digit text to display (mutually exclusive with [icon])
  final String? digit;

  /// The icon to display (mutually exclusive with [digit])
  final IconData? icon;

  /// The color of the text or icon
  final Color color;

  /// Callback when the button is pressed
  final Function(String?)? onPressed;

  /// Creates a digit button.
  ///
  /// Either [digit] or [icon] must be provided.
  /// [color] defaults to white.
  const DigitButton({required this.onPressed, super.key, this.digit, this.icon, this.color = Colors.white})
    : assert(digit != null || icon != null, 'Either digit or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: InkWell(
          highlightColor: themeData.highlightColor,
          customBorder: const CircleBorder(),
          onTap: onPressed == null ? null : () => onPressed?.call(digit),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  /// Builds the content of the button (either text or icon)
  Widget _buildContent() {
    if (digit != null) {
      return Text(
        digit!,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 20.0),
      );
    }

    return Icon(icon, color: color, size: 20.0);
  }
}
