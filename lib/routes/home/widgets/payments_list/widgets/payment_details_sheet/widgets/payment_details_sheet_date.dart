import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/date/breez_date_utils.dart';

class PaymentDetailsSheetDate extends StatelessWidget {
  final PaymentData paymentData;
  final AutoSizeGroup? labelAutoSizeGroup;

  const PaymentDetailsSheetDate({
    required this.paymentData,
    super.key,
    this.labelAutoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            texts.payment_details_sheet_date_time_label,
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            group: labelAutoSizeGroup,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              BreezDateUtils.formatYearMonthDayHourMinute(paymentData.paymentTime),
              style: themeData.primaryTextTheme.displaySmall!.copyWith(
                fontSize: 18.0,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
