import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:lottie/lottie.dart';

Future<dynamic> showPaymentSentSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const PaymentSentSheet(),
  );
}

class PaymentSentSheet extends StatefulWidget {
  const PaymentSentSheet({super.key});

  @override
  PaymentSentSheetState createState() => PaymentSentSheetState();
}

class PaymentSentSheetState extends State<PaymentSentSheet> {
  @override
  void initState() {
    super.initState();
    // Close the bottom sheet after 2.25 seconds
    Future<void>.delayed(const Duration(milliseconds: 2250), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: themeData.colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(),
            child: Lottie.asset(
              themeData.isLightTheme
                  ? 'assets/animations/lottie/payment_sent_light.json'
                  : 'assets/animations/lottie/payment_sent_dark.json',
              width: 128,
              height: 128,
              repeat: false,
              fit: BoxFit.fill,
            ),
          ),
          Text(
            texts.processing_payment_dialog_payment_sent,
            style: themeData.dialogTheme.titleTextStyle!.copyWith(
              fontSize: 24.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
