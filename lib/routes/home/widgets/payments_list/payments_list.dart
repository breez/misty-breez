import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';

export 'widgets/widgets.dart';

const double _kBottomPadding = 8.0;

class PaymentsList extends StatelessWidget {
  final List<PaymentData> paymentsList;
  final double paymentItemHeight;
  final GlobalKey firstPaymentItemKey;

  const PaymentsList({
    required this.paymentsList,
    required this.paymentItemHeight,
    required this.firstPaymentItemKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: paymentItemHeight + _kBottomPadding,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => PaymentItem(
          paymentsList[index],
          0 == index,
          firstPaymentItemKey,
        ),
        childCount: paymentsList.length,
      ),
    );
  }
}
