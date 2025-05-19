import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/extensions/extensions.dart';

class PaymentDetailsSheetContentTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsSheetContentTitle({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    String title = paymentData.title;
    if (title.isEmpty) {
      return Container();
    }

    if ((title == texts.payment_info_title_unknown || paymentData.details.hasBolt12Offer) &&
        paymentData.paymentType == PaymentType.receive) {
      final UserProfileCubit userProfileCubit = context.read<UserProfileCubit>();
      final UserProfileState userProfileState = userProfileCubit.state;
      title = '${userProfileState.profileSettings.name}';
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
