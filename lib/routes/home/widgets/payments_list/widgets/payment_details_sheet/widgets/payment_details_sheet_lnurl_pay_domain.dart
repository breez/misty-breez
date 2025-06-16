import 'package:flutter/material.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentDetailsSheetLnUrlPayDomain extends StatelessWidget {
  final String payDomain;

  const PaymentDetailsSheetLnUrlPayDomain({required this.payDomain, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      title: 'LNURL Pay Domain:',
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: payDomain,
    );
  }
}
