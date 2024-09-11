import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_item.dart';

const _kBottomPadding = 8.0;

class PaymentsList extends StatelessWidget {
  final double _itemHeight;
  final GlobalKey firstPaymentItemKey;

  const PaymentsList(
    this._itemHeight,
    this.firstPaymentItemKey, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (context, userprofileState) {
        return BlocBuilder<PaymentsCubit, PaymentsState>(
          builder: (context, paymentsState) {
            return SliverFixedExtentList(
              itemExtent: _itemHeight + _kBottomPadding,
              delegate: SliverChildBuilderDelegate(
                (context, index) => PaymentItem(
                  paymentsState.filteredPayments[index],
                  0 == index,
                  firstPaymentItemKey,
                ),
                childCount: paymentsState.filteredPayments.length,
              ),
            );
          },
        );
      },
    );
  }
}
