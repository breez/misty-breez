import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';

export 'refund_item_card_action.dart';
export 'refund_item_card_amount.dart';
export 'refund_item_card_header.dart';
export 'refund_item_card_original_tx.dart';

class RefundItemCard extends StatelessWidget {
  final RefundableSwap refundableSwap;

  const RefundItemCard({required this.refundableSwap, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Card(
      color: themeData.customData.paymentListBgColorLight,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RefundItemCardHeader(timestamp: refundableSwap.timestamp),
            const Divider(height: 24),
            RefundItemCardAmount(refundTxSat: refundableSwap.amountSat.toInt()),
            if (refundableSwap.swapAddress.isNotEmpty) ...<Widget>[
              RefundItemCardOriginalTx(swapAddress: refundableSwap.swapAddress),
            ],
            if (refundableSwap.lastRefundTxId != null &&
                refundableSwap.lastRefundTxId!.isNotEmpty) ...<Widget>[
              RefundItemCardAction(refundableSwap),
            ],
          ],
        ),
      ),
    );
  }
}
