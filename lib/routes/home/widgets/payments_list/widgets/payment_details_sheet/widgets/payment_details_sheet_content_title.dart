import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/extensions/payment_title_extension.dart';

class PaymentDetailsSheetContentTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsSheetContentTitle({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    String title = paymentData.title;
    if (title.isEmpty) {
      return Container();
    }
    if (paymentData.paymentType == PaymentType.receive && title.isDefaultTitleWithLiquidNaming) {
      final UserProfileCubit userProfileCubit = context.read<UserProfileCubit>();
      final UserProfileState userProfileState = userProfileCubit.state;
      title = 'Payment to ${userProfileState.profileSettings.name}';
    }
    return AutoSizeText(
      title,
      style: themeData.primaryTextTheme.titleLarge!.copyWith(
        fontSize: 20.0,
        color: Colors.white,
        height: 1.234,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
