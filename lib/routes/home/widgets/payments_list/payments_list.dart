import 'package:flutter/material.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_item.dart';

const _kBottomPadding = 8.0;

class PaymentsList extends StatelessWidget {
  final List<PaymentMinutiae> _payments;
  final double _itemHeight;
  final GlobalKey firstPaymentItemKey;

  const PaymentsList(
    this._payments,
    this._itemHeight,
    this.firstPaymentItemKey, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: _itemHeight + _kBottomPadding,
      delegate: SliverChildBuilderDelegate(
        (context, index) => PaymentItem(
          _payments[index],
          0 == index,
          firstPaymentItemKey,
        ),
        childCount: _payments.length,
      ),
    );
  }
}
