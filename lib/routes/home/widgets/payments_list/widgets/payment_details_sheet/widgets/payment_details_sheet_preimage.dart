import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/widgets/widgets.dart';

class PaymentDetailsSheetPreimage extends StatelessWidget {
  final String paymentPreimage;

  const PaymentDetailsSheetPreimage({required this.paymentPreimage, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      title: '${texts.payment_details_dialog_single_info_pre_image}:',
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: paymentPreimage,
    );
  }
}