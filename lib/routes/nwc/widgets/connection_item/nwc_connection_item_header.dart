import 'package:flutter/material.dart';

class NwcConnectionItemHeader extends StatelessWidget {
  final String connectionName;
  final bool isExpiringWithinWeek;

  const NwcConnectionItemHeader({
    required this.connectionName,
    required this.isExpiringWithinWeek,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: const ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12.0))),
        color: Color(0xFF142340),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              connectionName,
              style: themeData.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isExpiringWithinWeek)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFB923C).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                'Expiring soon',
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFB923C),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
