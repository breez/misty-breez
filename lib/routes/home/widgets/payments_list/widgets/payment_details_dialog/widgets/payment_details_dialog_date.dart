import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/date.dart';

class PaymentDetailsDialogDate extends StatelessWidget {
  final PaymentData paymentData;
  final AutoSizeGroup? labelAutoSizeGroup;
  final AutoSizeGroup? valueAutoSizeGroup;

  const PaymentDetailsDialogDate({
    required this.paymentData,
    super.key,
    this.labelAutoSizeGroup,
    this.valueAutoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Container(
      height: 36.0,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AutoSizeText(
              texts.payment_details_dialog_date_and_time,
              style: themeData.primaryTextTheme.headlineMedium,
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
              child: AutoSizeText(
                BreezDateUtils.formatYearMonthDayHourMinute(paymentData.paymentTime),
                style: themeData.primaryTextTheme.displaySmall,
                textAlign: TextAlign.right,
                maxLines: 1,
                group: valueAutoSizeGroup,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
