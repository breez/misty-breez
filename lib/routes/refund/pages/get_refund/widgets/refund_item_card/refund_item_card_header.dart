import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/utils/utils.dart';

class RefundItemCardHeader extends StatelessWidget {
  final int timestamp;

  const RefundItemCardHeader({required this.timestamp, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    final String dateFormatted = BreezDateUtils.formatYearMonthDayHourMinuteSecond(
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                texts.get_refund_transaction,
                style: themeData.primaryTextTheme.headlineMedium!.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormatted,
                style: themeData.primaryTextTheme.displaySmall!.copyWith(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
