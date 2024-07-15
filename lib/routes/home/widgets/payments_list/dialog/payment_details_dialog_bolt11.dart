import 'package:flutter/material.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/dialog/shareable_payment_row.dart';

class PaymentDetailsBolt11 extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsBolt11({super.key, required this.paymentMinutiae});

  @override
  Widget build(BuildContext context) {
    final bolt11 = paymentMinutiae.bolt11;
    if (bolt11.isNotEmpty) {
      return ShareablePaymentRow(
        title: "Invoice",
        sharedValue: bolt11,
      );
    } else {
      return Container();
    }
  }
}
