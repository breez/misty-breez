import 'package:flutter/material.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentInfoMessageBox extends StatelessWidget {
  final String message;

  const PaymentInfoMessageBox({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return WarningBox(
      boxPadding: EdgeInsets.zero,
      backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
      contentPadding: const EdgeInsets.all(16.0),
      child: Text(
        message,
        style: themeData.textTheme.titleLarge?.copyWith(
          color: themeData.colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
