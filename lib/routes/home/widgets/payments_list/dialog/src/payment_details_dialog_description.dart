import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/payment_details_extension.dart';
import 'package:l_breez/utils/extensions/payment_title_extension.dart';

class PaymentDetailsDialogDescription extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsDialogDescription({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    var title = paymentData.title;
    if (paymentData.paymentType == PaymentType.receive && title.isDefaultTitleWithLiquidNaming) {
      final userProfileCubit = context.read<UserProfileCubit>();
      final userProfileState = userProfileCubit.state;
      title = "Payment to ${userProfileState.profileSettings.name}";
    }
    final description = paymentData.details.map(
      lightning: (details) => details.description,
      bitcoin: (details) => details.description,
      liquid: (details) => details.description,
      orElse: () => "",
    );
    if (description.isEmpty || title == description) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 54,
          minWidth: double.infinity,
        ),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: AutoSizeText(
              description,
              style: themeData.primaryTextTheme.headlineMedium,
              textAlign:
                  description.length > 40 && !description.contains("\n") ? TextAlign.start : TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
