import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

class RefundItemCardAction extends StatelessWidget {
  final RefundableSwap refundableSwap;
  final String lastRefundTxId;

  const RefundItemCardAction({
    required this.refundableSwap,
    required this.lastRefundTxId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: SubmitButton(
          lastRefundTxId.isNotEmpty ? texts.get_refund_action_broadcasted : texts.get_refund_action_continue,
          () {
            Navigator.of(context).pushNamed(
              RefundPage.routeName,
              arguments: refundableSwap,
            );
          },
          enabled: lastRefundTxId.isEmpty,
        ),
      ),
    );
  }
}
