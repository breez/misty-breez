import 'package:flutter/material.dart';

class FeeOptionButton extends StatelessWidget {
  final int index;
  final String text;
  final bool isAffordable;
  final bool isSelected;
  final Function onSelect;

  const FeeOptionButton({
    required this.index,
    required this.text,
    required this.isAffordable,
    required this.isSelected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Color borderColor = themeData.colorScheme.onSurface.withValues(alpha: .4);
    final Border border = Border.all(color: borderColor);
    final BorderRadius borderRadius = BorderRadius.only(
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
            text.toUpperCase(),
            style: themeData.textTheme.labelLarge!.copyWith(
              color: !isAffordable
                  ? themeData.primaryColor.withValues(alpha: .4)
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
