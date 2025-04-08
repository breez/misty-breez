import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentDetailsSheetPreimage extends StatelessWidget {
  final String paymentPreimage;
  final String? invoice;

  const PaymentDetailsSheetPreimage({
    required this.paymentPreimage,
    required this.invoice,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      title: texts.payment_details_sheet_preimage_label,
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: paymentPreimage,
      isURL: invoice != null,
      urlValue: LnPaymentValidatorService.formatValidatorUrl(
        invoice: invoice!,
        preimage: paymentPreimage,
      ),
    );
  }
}
