import 'package:flutter/material.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/theme/theme.dart';

class PaymentItemTitle extends StatelessWidget {
  final PaymentMinutiae _paymentMinutiae;

  const PaymentItemTitle(
    this._paymentMinutiae, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _paymentMinutiae.title,
      style: Theme.of(context).paymentItemTitleTextStyle,
      overflow: TextOverflow.ellipsis,
    );
  }
}
