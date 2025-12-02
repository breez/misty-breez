import 'package:flutter/material.dart';

class NwcConnectionItemInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const NwcConnectionItemInfoRow({
    required this.label,
    required this.value,
    this.labelColor = const Color(0xFF9CA3AF),
    this.valueColor = Colors.white,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return SizedBox(
      height: 32,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: themeData.textTheme.bodySmall?.copyWith(color: labelColor, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(color: valueColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
