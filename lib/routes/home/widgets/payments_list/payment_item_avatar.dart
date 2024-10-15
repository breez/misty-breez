import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/extensions/payment_title_extension.dart';
import 'package:l_breez/widgets/breez_avatar.dart';

class PaymentItemAvatar extends StatelessWidget {
  final PaymentData paymentData;
  final double radius;

  const PaymentItemAvatar(this.paymentData, {this.radius = 20.0, super.key});

  @override
  Widget build(BuildContext context) {
    var title = paymentData.title;
    if (paymentData.paymentType == PaymentType.receive && title.isDefaultTitleWithLiquidNaming) {
      final userProfileCubit = context.read<UserProfileCubit>();
      final userProfileState = userProfileCubit.state;
      final user = userProfileState.profileSettings;
      return BreezAvatar(user.avatarURL, radius: radius);
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Icon(
          paymentData.paymentType == PaymentType.receive ? Icons.add_rounded : Icons.remove_rounded,
          color: const Color(0xb3303234),
        ),
      );
    }
  }
}
