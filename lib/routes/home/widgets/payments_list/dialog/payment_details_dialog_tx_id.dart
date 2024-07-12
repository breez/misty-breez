import 'package:flutter/widgets.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/dialog/shareable_payment_row.dart';
import 'package:l_breez/utils/blockchain_explorer_utils.dart';

class PaymentDetailsTxId extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsTxId({required this.paymentMinutiae, super.key});

  @override
  Widget build(BuildContext context) {
    final txId = paymentMinutiae.txId;
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
