import 'package:flutter/material.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentDetailsSheetPayerNote extends StatelessWidget {
  final String payerNote;

  const PaymentDetailsSheetPayerNote({required this.payerNote, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      // TODO(erdemyerebasmaz): Add message to Breez-Translations
      title: 'Payer Note:',
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: payerNote,
    );
  }
}
