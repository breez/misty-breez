import 'package:flutter/material.dart';
import 'package:misty_breez/theme/src/theme.dart';

class NwcConnectionItemHeader extends StatelessWidget {
  final String connectionName;
  final bool hasPeriodicBudget;
  final bool isExpiringWithinWeek;

  const NwcConnectionItemHeader({
    required this.connectionName,
    required this.hasPeriodicBudget,
    required this.isExpiringWithinWeek,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(12.0),
            bottom: Radius.circular(hasPeriodicBudget ? 0.0 : 12.0),
          ),
        ),
        color: const Color(0xFF142340),
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
              decoration: BoxDecoration(color: warningBoxColor, borderRadius: BorderRadius.circular(12.0)),
              child: Text(
                'Expires soon',
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).errorTextStyle.color,
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
