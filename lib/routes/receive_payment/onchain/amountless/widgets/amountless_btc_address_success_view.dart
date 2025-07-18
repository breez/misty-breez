import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';

class AmountlessBtcAddressSuccessView extends StatelessWidget {
  final AmountlessBtcState amountlessBtcState;

  const AmountlessBtcAddressSuccessView(this.amountlessBtcState, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              decoration: ShapeDecoration(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                color: themeData.customData.surfaceBgColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
              child: Column(
                children: <Widget>[
                  DestinationWidget(
                    destination: amountlessBtcState.address,
                    paymentLabel: texts.receive_payment_method_btc_address,
                    infoWidget: AmountlessBtcAddressMessageBox(amountlessBtcState),
                    isBitcoinPayment: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
