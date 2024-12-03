import 'package:flutter/material.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:lottie/lottie.dart';

class PaymentReceivedContent extends StatelessWidget {
  const PaymentReceivedContent({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
            'Payment Received',
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
