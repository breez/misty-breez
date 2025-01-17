import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/utils/date.dart';

class PaymentDetailsSheetExpiry extends StatelessWidget {
  final DateTime expiryDate;
  final AutoSizeGroup? labelAutoSizeGroup;

  const PaymentDetailsSheetExpiry({
    required this.expiryDate,
    this.labelAutoSizeGroup,
    super.key,
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
            '${texts.payment_details_dialog_expiration}:',
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
              BreezDateUtils.formatYearMonthDayHourMinute(expiryDate),
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
