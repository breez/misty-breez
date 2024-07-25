import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/models/payment_minutiae.dart';

class PaymentDetailsDialogDescription extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsDialogDescription({required this.paymentMinutiae, super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final title = paymentMinutiae.title;
    final description = paymentMinutiae.description;
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
