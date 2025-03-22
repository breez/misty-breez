import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/theme/src/theme.dart';
import 'package:misty_breez/utils/utils.dart';

final AutoSizeGroup textGroup = AutoSizeGroup();

class GridActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const GridActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MinFontSize minFont = MinFontSize(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 138.0,
      ),
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(icon, size: 20.0),
          label: AutoSizeText(
            label.toUpperCase(),
            style: balanceFiatConversionTextStyle,
            maxLines: 1,
            group: textGroup,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
