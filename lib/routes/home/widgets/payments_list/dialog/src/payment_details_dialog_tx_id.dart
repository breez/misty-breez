import 'package:flutter/widgets.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/utils/blockchain_explorer_utils.dart';
import 'package:l_breez/widgets/shareable_payment_row.dart';

class PaymentDetailsTxId extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsTxId({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final txId = paymentData.txId;
    return txId.isNotEmpty
        ? ShareablePaymentRow(
            // TODO: Move this message to Breez-Translations
            title: "Transaction ID",
            sharedValue: txId,
            isURL: true,
            urlValue: BlockChainExplorerUtils().formatTransactionUrl(txid: txId),
          )
        : const SizedBox.shrink();
  }
}
