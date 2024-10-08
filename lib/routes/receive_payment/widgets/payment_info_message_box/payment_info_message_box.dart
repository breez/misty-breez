import 'package:flutter/material.dart';
import 'package:l_breez/widgets/warning_box.dart';

class PaymentInfoMessageBox extends StatelessWidget {
  final String message;

  const PaymentInfoMessageBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return WarningBox(
      boxPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Text(
        message,
        style: themeData.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
