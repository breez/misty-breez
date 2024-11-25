import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';

Future<dynamic> showProcessingPaymentSheet(
  BuildContext context, {
  required Future<dynamic> Function() paymentFunc,
  bool isLnUrlPayment = false,
}) async {
  return await showModalBottomSheet(
    context: context,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => ProcessingPaymentSheet(
      isLnUrlPayment: isLnUrlPayment,
      paymentFunc: paymentFunc,
    ),
  );
}

class ProcessingPaymentSheet extends StatefulWidget {
  final bool isLnUrlPayment;
  final Future<dynamic> Function() paymentFunc;

  const ProcessingPaymentSheet({
    required this.paymentFunc,
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
          Navigator.of(context).pop();
          final BreezTranslations texts = getSystemAppLocalizations();
          showFlushbar(context, message: texts.payment_error_to_send_unknown_reason);
        }
      } else {
        Navigator.of(context).pop();
      }
    }).catchError((Object err) {
      Navigator.of(context).pop(err);
      if (err is FrbException || err is PaymentError_PaymentTimeout) {
        final BreezTranslations texts = getSystemAppLocalizations();
        final String message = extractExceptionMessage(err, texts);
        showFlushbar(context, message: texts.payment_error_to_send(message));
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
