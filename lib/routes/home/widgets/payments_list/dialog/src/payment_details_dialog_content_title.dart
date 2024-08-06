import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/payments/models/models.dart';

class PaymentDetailsDialogContentTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsDialogContentTitle({super.key, required this.paymentData});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final title = paymentData.title;
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
