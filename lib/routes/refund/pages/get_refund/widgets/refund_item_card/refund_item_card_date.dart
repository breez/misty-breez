import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/utils/utils.dart';

class RefundItemCardDate extends StatelessWidget {
  final int timestamp;
  final AutoSizeGroup? labelAutoSizeGroup;

  const RefundItemCardDate({
    required this.timestamp,
    this.labelAutoSizeGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    final String dateFormatted = BreezDateUtils.formatYearMonthDay(
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            'Date:',
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
              dateFormatted,
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
