import 'package:flutter/material.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/theme/theme.dart';

class PaymentItemTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentItemTitle(
    this.paymentData, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      paymentData.title,
      style: Theme.of(context).paymentItemTitleTextStyle,
      overflow: TextOverflow.ellipsis,
    );
  }
}
