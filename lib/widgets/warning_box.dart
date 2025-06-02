import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';

class WarningBox extends StatelessWidget {
  final EdgeInsets boxPadding;
  final EdgeInsets contentPadding;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const WarningBox({
    required this.child,
    super.key,
    this.boxPadding = const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12.3, vertical: 16.2),
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: boxPadding,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? warningBoxColor,
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Container(
          padding: contentPadding,
          width: MediaQuery.of(context).size.width,
          decoration: DottedDecoration(
            shape: Shape.box,
            dash: const <int>[3, 2],
            color: borderColor ?? Theme.of(context).warningBoxBorderColor,
            borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          ),
          child: child,
        ),
      ),
    );
  }
}
