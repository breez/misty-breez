import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

export 'refund_item_card_action.dart';
export 'refund_item_card_amount.dart';
export 'refund_item_card_date.dart';

final AutoSizeGroup _labelGroup = AutoSizeGroup();

class RefundItemCard extends StatelessWidget {
  final RefundableSwap refundableSwap;

  const RefundItemCard({required this.refundableSwap, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    final String lastRefundTxId = refundableSwap.lastRefundTxId ?? '';

    return Card(
      color: themeData.customData.surfaceBgColor,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShareablePaymentRow(
              isExpanded: true,
              tilePadding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              title: 'Transaction',
              titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
                fontSize: 18.0,
                color: Colors.white,
              ),
              sharedValue: lastRefundTxId.isNotEmpty ? lastRefundTxId : refundableSwap.swapAddress,
              isURL: true,
              urlValue: lastRefundTxId.isNotEmpty
                  ? BlockchainExplorerService.formatTransactionUrl(
                      txid: lastRefundTxId,
                      mempoolInstance: NetworkConstants.defaultBitcoinMempoolInstance,
                    )
                  : BlockchainExplorerService.formatAddressUrl(
                      address: refundableSwap.swapAddress,
                      mempoolInstance: NetworkConstants.defaultBitcoinMempoolInstance,
                    ),
            ),
            const Divider(height: 32.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
            RefundItemCardAmount(
              refundTxSat: refundableSwap.amountSat.toInt(),
              labelAutoSizeGroup: _labelGroup,
            ),
            const Divider(height: 32.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
            RefundItemCardDate(timestamp: refundableSwap.timestamp, labelAutoSizeGroup: _labelGroup),
            const Divider(height: 32.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
            RefundItemCardAction(refundableSwap: refundableSwap, lastRefundTxId: lastRefundTxId),
          ],
        ),
      ),
    );
  }
}
