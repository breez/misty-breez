import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/theme/theme.dart';

class PaymentItemTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentItemTitle(this.paymentData, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    String title = paymentData.title;
    if ((title == texts.payment_info_title_unknown || paymentData.details.hasBolt12Offer) &&
        paymentData.paymentType == PaymentType.receive) {
      final UserProfileCubit userProfileCubit = context.read<UserProfileCubit>();
      final UserProfileState userProfileState = userProfileCubit.state;
      title = '${userProfileState.profileSettings.name}';
    }
    return Text(title, style: Theme.of(context).paymentItemTitleTextStyle, overflow: TextOverflow.ellipsis);
  }
}
