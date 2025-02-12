import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';

Future<dynamic> showProcessingPaymentSheet(
  BuildContext context, {
  required Future<dynamic> Function() paymentFunc,
  bool promptError = false,
  bool popToHomeOnCompletion = false,
  bool isLnUrlPayment = false,
}) async {
  return await showModalBottomSheet(
    context: context,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => ProcessingPaymentSheet(
      isLnUrlPayment: isLnUrlPayment,
      promptError: promptError,
      popToHomeOnCompletion: popToHomeOnCompletion,
      paymentFunc: paymentFunc,
    ),
  );
}

class ProcessingPaymentSheet extends StatefulWidget {
  final bool isLnUrlPayment;
  final bool promptError;
  final bool popToHomeOnCompletion;
  final Future<dynamic> Function() paymentFunc;

  const ProcessingPaymentSheet({
    required this.paymentFunc,
    this.promptError = false,
    this.popToHomeOnCompletion = false,
    this.isLnUrlPayment = false,
    super.key,
  });

  @override
  ProcessingPaymentSheetState createState() => ProcessingPaymentSheetState();
}

class ProcessingPaymentSheetState extends State<ProcessingPaymentSheet> {
  bool _showPaymentSent = false;

  @override
  void initState() {
    super.initState();
    _payAndClose();
  }

  void _payAndClose() {
    widget.paymentFunc().then((dynamic payResult) async {
      if (!mounted) {
        return;
      }
      if (widget.isLnUrlPayment) {
        if (payResult is LnUrlPayResult) {
          if (payResult is LnUrlPayResult_EndpointSuccess) {
            setState(() {
              _showPaymentSent = true;
            });
          }
          // Close the bottom sheet after 2.25 seconds
          Future<void>.delayed(const Duration(milliseconds: 2250), () {
            if (mounted) {
              Navigator.of(context).pop(payResult);
            }
          });
        } else {
          if (mounted) {
            Navigator.of(context).pop();
            final BreezTranslations texts = getSystemAppLocalizations();
            showFlushbar(
              context,
              message: texts.payment_error_to_send_unknown_reason,
            );
          }
        }
      } else {
        if (mounted) {
          final NavigatorState navigator = Navigator.of(context);
          if (widget.popToHomeOnCompletion) {
            navigator.pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);
          } else {
            navigator.pop();
          }
        }
      }
    }).catchError((Object err) {
      if (mounted) {
        Navigator.of(context).pop(err);
        if (widget.promptError) {
          final BreezTranslations texts = getSystemAppLocalizations();
          final ThemeData themeData = Theme.of(context);
          promptError(
            context,
            texts.payment_failed_report_dialog_title,
            Text(
              extractExceptionMessage(err, texts),
              style: themeData.dialogTheme.contentTextStyle,
            ),
          );
        } else if (err is FrbException || err is PaymentError_PaymentTimeout) {
          final BreezTranslations texts = getSystemAppLocalizations();
          final String message = extractExceptionMessage(err, texts);
          showFlushbar(context, message: texts.payment_error_to_send(message));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: themeData.colorScheme.surface,
      child: _showPaymentSent ? const PaymentSentContent() : const ProcessingPaymentContent(),
    );
  }
}
