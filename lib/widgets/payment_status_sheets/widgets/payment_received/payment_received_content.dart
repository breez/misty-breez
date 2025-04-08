import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:misty_breez/theme/theme.dart';

class PaymentReceivedContent extends StatelessWidget {
  const PaymentReceivedContent({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            texts.payment_received_content_title,
            style: themeData.dialogTheme.titleTextStyle!.copyWith(
              fontSize: 24.0,
              color: themeData.isLightTheme ? null : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Lottie.asset(
          themeData.isLightTheme
              ? 'assets/animations/lottie/payment_sent_light.json'
              : 'assets/animations/lottie/payment_sent_dark.json',
          width: 128.0,
          height: 128.0,
          repeat: false,
          fit: BoxFit.fill,
        ),
      ],
    );
  }
}
