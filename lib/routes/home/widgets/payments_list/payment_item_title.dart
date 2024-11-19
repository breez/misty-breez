import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/extensions/payment_title_extension.dart';

class PaymentItemTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentItemTitle(
    this.paymentData, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String title = paymentData.title;
    if (paymentData.paymentType == PaymentType.receive && title.isDefaultTitleWithLiquidNaming) {
      final UserProfileCubit userProfileCubit = context.read<UserProfileCubit>();
      final UserProfileState userProfileState = userProfileCubit.state;
      title = 'Payment to ${userProfileState.profileSettings.name}';
    }
    return Text(
      title,
      style: Theme.of(context).paymentItemTitleTextStyle,
      overflow: TextOverflow.ellipsis,
    );
  }
}
