import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/services/services.dart';
import 'package:l_breez/widgets/widgets.dart';

class PaymentDetailsSheetTxId extends StatelessWidget {
  final String txId;
  final String unblindingData;

  const PaymentDetailsSheetTxId({required this.txId, required this.unblindingData, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      title: '${texts.payment_details_dialog_single_info_tx_id}:',
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: txId,
      isURL: true,
      urlValue: BlockchainExplorerService.formatTransactionUrl(
        txid: txId,
        unblindingData: unblindingData,
      ),
    );
  }
}
