import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/models/payment_details_extension.dart';

class PaymentDetailsDialogDescription extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsDialogDescription({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final title = paymentData.title;
    final description = paymentData.details?.maybeMap(
          lightning: (details) => details.description,
          bitcoin: (details) => details.description,
          liquid: (details) => details.description,
          orElse: () => "",
        ) ??
        "";
    if (description.isEmpty || title == description) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 54,
          minWidth: double.infinity,
        ),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: AutoSizeText(
              description,
              style: themeData.primaryTextTheme.headlineMedium,
              textAlign:
                  description.length > 40 && !description.contains("\n") ? TextAlign.start : TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
