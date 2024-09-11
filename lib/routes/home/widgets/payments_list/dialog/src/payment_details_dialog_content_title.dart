import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/extensions/payment_title_extension.dart';

class PaymentDetailsDialogContentTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsDialogContentTitle({super.key, required this.paymentData});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    var title = paymentData.title;
    if (title.isEmpty) {
      return Container();
    }
    if (paymentData.paymentType == PaymentType.receive && title.isDefaultTitleWithLiquidNaming) {
      final userProfileCubit = context.read<UserProfileCubit>();
      final userProfileState = userProfileCubit.state;
      title = "Payment to ${userProfileState.profileSettings.name}";
    }
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 8,
      ),
      child: AutoSizeText(
        title,
        style: themeData.primaryTextTheme.titleLarge,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
