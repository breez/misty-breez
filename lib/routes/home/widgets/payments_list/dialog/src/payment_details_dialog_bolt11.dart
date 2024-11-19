import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/models/payment_details_extension.dart';
import 'package:l_breez/widgets/shareable_payment_row.dart';

class PaymentDetailsBolt11 extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsBolt11({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final String bolt11 = paymentData.details.map(
          lightning: (PaymentDetails_Lightning details) => details.bolt11,
          orElse: () => '',
        ) ??
        '';

    if (bolt11.isEmpty) {
      return const SizedBox.shrink();
    }

    return ShareablePaymentRow(
      title: 'Invoice',
      sharedValue: bolt11,
    );
  }
}
