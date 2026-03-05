import 'package:flutter/material.dart';
import 'package:misty_breez/widgets/widgets.dart';

class NwcConnectionUriCard extends StatelessWidget {
  final String connectionString;

  const NwcConnectionUriCard({required this.connectionString, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      title: 'Connection URI:',
      sharedValue: connectionString,
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      shouldPop: false,
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
    );
  }
}
