import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/date.dart';

class PaymentItemSubtitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentItemSubtitle(
    this.paymentData, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();
    final subtitleTextStyle = themeData.paymentItemSubtitleTextStyle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          BreezDateUtils.formatTimelineRelative(paymentData.paymentTime),
          style: subtitleTextStyle,
        ),
        if (paymentData.status == PaymentState.pending) ...[
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
