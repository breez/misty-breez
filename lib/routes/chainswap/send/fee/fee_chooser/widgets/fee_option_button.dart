import 'package:flutter/material.dart';

class FeeOptionButton extends StatelessWidget {
  final int index;
  final String text;
  final bool isAffordable;
  final bool isSelected;
  final Function onSelect;

  const FeeOptionButton({
    super.key,
    required this.index,
    required this.text,
    required this.isAffordable,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final borderColor = themeData.colorScheme.onSurface.withOpacity(0.4);
    Border border = Border.all(color: borderColor);
    BorderRadius borderRadius = BorderRadius.only(
      topLeft: index == 2 ? Radius.zero : Radius.circular((index == 0) ? 5.0 : 0.0),
      bottomLeft: index == 2 ? Radius.zero : Radius.circular((index == 0) ? 5.0 : 0.0),
      topRight: index == 2 ? const Radius.circular(5.0) : Radius.zero,
      bottomRight: index == 2 ? const Radius.circular(5.0) : Radius.zero,
    );

    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: isSelected ? themeData.colorScheme.onSurface : themeData.canvasColor,
          border: border,
        ),
        child: TextButton(
          onPressed: isAffordable ? () => onSelect() : null,
          child: Text(
            text,
            style: themeData.textTheme.labelLarge!.copyWith(
              color: !isAffordable
                  ? themeData.primaryColor.withOpacity(0.4)
                  : isSelected
                      ? themeData.canvasColor
                      : themeData.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
