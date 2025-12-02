import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/routes/routes.dart';

class NwcConnectionInfoCard extends StatelessWidget {
  final String connectionName;

  const NwcConnectionInfoCard({required this.connectionName, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeData.customData.surfaceBgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatusItem(label: 'Connection Name', value: connectionName),
    );
  }
}
