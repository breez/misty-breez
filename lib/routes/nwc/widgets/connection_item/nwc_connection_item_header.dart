import 'package:flutter/material.dart';
import 'package:misty_breez/theme/src/theme_extensions.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF142340),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
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
