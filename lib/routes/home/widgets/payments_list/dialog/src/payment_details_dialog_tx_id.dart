import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/widgets.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/utils/blockchain_explorer_utils.dart';
import 'package:l_breez/widgets/shareable_payment_row.dart';

class PaymentDetailsTxId extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsTxId({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final String txId = paymentData.txId;
    final BreezTranslations texts = context.texts();

    return txId.isNotEmpty
        ? ShareablePaymentRow(
            title: texts.payment_details_dialog_single_info_tx_id,
            sharedValue: txId,
            isURL: true,
            urlValue: BlockChainExplorerUtils().formatTransactionUrl(txid: txId),
          )
        : const SizedBox.shrink();
  }
}
