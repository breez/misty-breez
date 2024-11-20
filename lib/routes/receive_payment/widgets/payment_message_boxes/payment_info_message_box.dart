import 'package:flutter/material.dart';
import 'package:l_breez/widgets/widgets.dart';

class PaymentInfoMessageBox extends StatelessWidget {
  final String message;

  const PaymentInfoMessageBox({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return WarningBox(
      boxPadding: const EdgeInsets.symmetric(vertical: 16),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Text(
        message,
        style: themeData.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
