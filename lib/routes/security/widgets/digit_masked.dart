import 'package:flutter/material.dart';

/// A widget that displays a masked PIN digit, either filled or empty.
class DigitMasked extends StatelessWidget {
  /// The size of the digit indicator
  final double size;

  /// Whether the digit indicator is filled
  final bool filled;

  /// The color when filled
  final Color filledColor;

  /// The color when not filled
  final Color unfilledColor;

  /// Creates a masked digit indicator.
  ///
  /// [size] The size of the indicator (default: 32)
  /// [filled] Whether the indicator is filled (default: false)
  /// [filledColor] The color when filled (default: white)
  /// [unfilledColor] The color when not filled (default: transparent)
  const DigitMasked({
    super.key,
    this.size = 32,
    this.filled = false,
    this.filledColor = Colors.white,
    this.unfilledColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: <Widget>[_buildOuterCircle(), _buildInnerCircle()]);
  }

  /// Builds the outer circle (border)
  Widget _buildOuterCircle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.only(top: 24.0),
      margin: const EdgeInsets.only(),
      curve: filled ? Curves.decelerate : Curves.easeIn,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: unfilledColor,
        shape: BoxShape.circle,
        border: Border.all(color: filledColor, width: 2.0),
      ),
    );
  }

  /// Builds the inner circle (fill)
  Widget _buildInnerCircle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.only(top: 24.0),
      margin: const EdgeInsets.only(),
      curve: filled ? Curves.decelerate : Curves.easeIn,
      alignment: Alignment.center,
      width: filled ? size : 0,
      height: filled ? size : 0,
      decoration: BoxDecoration(
        color: filledColor,
        shape: BoxShape.circle,
        border: Border.all(color: filled ? filledColor : unfilledColor, width: 2.0),
      ),
    );
  }
}
