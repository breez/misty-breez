import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/utils.dart';

class PaymentDetailsSheetDescription extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsSheetDescription({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    String title = paymentData.title;
    if (title == texts.payment_info_title_unknown && paymentData.paymentType == PaymentType.receive) {
      final UserProfileCubit userProfileCubit = context.read<UserProfileCubit>();
      final UserProfileState userProfileState = userProfileCubit.state;
      title = '${userProfileState.profileSettings.name}';
    }
    final String description = paymentData.description;
    if (description.isEmpty || title == description || description.isDefaultDescription) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 54,
          minWidth: double.infinity,
        ),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: AutoSizeText(
              description,
              style: themeData.primaryTextTheme.displaySmall!.copyWith(
                fontSize: 20,
                color: Colors.white70,
                height: 1.208,
              ),
              textAlign:
                  description.length > 60 && !description.contains('\n') ? TextAlign.start : TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
