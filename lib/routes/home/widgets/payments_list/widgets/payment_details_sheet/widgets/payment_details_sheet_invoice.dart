import 'package:flutter/material.dart';
import 'package:l_breez/widgets/widgets.dart';

class PaymentDetailsSheetInvoice extends StatelessWidget {
  final String invoice;

  const PaymentDetailsSheetInvoice({required this.invoice, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      title: 'Invoice:',
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: invoice,
    );
  }
}
