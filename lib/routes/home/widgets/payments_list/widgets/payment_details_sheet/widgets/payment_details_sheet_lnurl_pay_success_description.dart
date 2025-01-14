//import 'package:breez_translations/breez_translations_locales.dart';
//import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/widgets/widgets.dart';

class PaymentDetailsSheetLnUrlPaySuccessDescription extends StatelessWidget {
  final String paySuccessDescription;

  const PaymentDetailsSheetLnUrlPaySuccessDescription({required this.paySuccessDescription, super.key});

  @override
  Widget build(BuildContext context) {
    //final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      // TODO(danielgranhao): translate.
      title: 'LNURL Pay Success Description:',
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: paySuccessDescription,
    );
  }
}
