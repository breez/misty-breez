import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/utils/date.dart';
import 'package:flutter/material.dart';

class PaymentItemSubtitle extends StatelessWidget {
  final PaymentMinutiae _paymentMinutiae;

  const PaymentItemSubtitle(
    this._paymentMinutiae, {
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
          BreezDateUtils.formatTimelineRelative(_paymentMinutiae.paymentTime),
          style: subtitleTextStyle,
        ),
        _paymentMinutiae.status == PaymentState.pending
            ? Text(
                texts.wallet_dashboard_payment_item_balance_pending_suffix,
                style: subtitleTextStyle.copyWith(
                  color: themeData.customData.pendingTextColor,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
