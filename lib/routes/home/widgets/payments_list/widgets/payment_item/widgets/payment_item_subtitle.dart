import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/date/breez_date_utils.dart';

class PaymentItemSubtitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentItemSubtitle(
    this.paymentData, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final BreezTranslations texts = context.texts();
    final TextStyle subtitleTextStyle = themeData.paymentItemSubtitleTextStyle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          BreezDateUtils.formatTimelineRelative(paymentData.paymentTime),
          style: subtitleTextStyle,
        ),
        if (paymentData.status == PaymentState.refundPending) ...<Widget>[
          Text(
            ' (Pending Refund)',
            style: subtitleTextStyle.copyWith(
              color: themeData.customData.pendingTextColor,
            ),
          ),
        ],
        if (paymentData.isRefunded || paymentData.status == PaymentState.refundable) ...<Widget>[
          Text(
            ' (Failed)',
            style: subtitleTextStyle.copyWith(
              color: themeData.isLightTheme ? Colors.red : themeData.colorScheme.error,
            ),
          ),
        ],
        if (paymentData.status == PaymentState.pending) ...<Widget>[
          Text(
            texts.wallet_dashboard_payment_item_balance_pending_suffix,
            style: subtitleTextStyle.copyWith(
              color: themeData.customData.pendingTextColor,
            ),
          ),
        ],
      ],
    );
  }
}
