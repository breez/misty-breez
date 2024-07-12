import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/models/payment_minutiae.dart';

class PaymentDetailsDialogContentTitle extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsDialogContentTitle({super.key, required this.paymentMinutiae});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final title = paymentMinutiae.title;
    if (title.isEmpty) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 8,
      ),
      child: AutoSizeText(
        title,
        style: themeData.primaryTextTheme.titleLarge,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
