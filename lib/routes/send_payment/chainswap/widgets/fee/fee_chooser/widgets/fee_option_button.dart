import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';

final AutoSizeGroup autoSizeGroup = AutoSizeGroup();

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
          color: !isAffordable
              ? themeData.disabledColor
              : isSelected
                  ? themeData.primaryColor
                  : themeData.customData.surfaceBgColor,
          border: border,
        ),
        child: TextButton(
          onPressed: isAffordable ? () => onSelect() : null,
          child: AutoSizeText(
            text.toUpperCase(),
            style: themeData.textTheme.labelLarge!.copyWith(
              fontSize: 16.0,
              color: !isAffordable
                  ? Colors.white.withValues(alpha: .4)
                  : isSelected
                      ? Colors.white
                      : Colors.white,
            ),
            maxLines: 1,
            group: autoSizeGroup,
            stepGranularity: 0.1,
          ),
        ),
      ),
    );
  }
}
