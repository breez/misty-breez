import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentDetailsSheetTxId extends StatelessWidget {
  final String txId;
  final String unblindingData;
  final bool isBtcTx;

  const PaymentDetailsSheetTxId({
    required this.txId,
    required this.unblindingData,
    this.isBtcTx = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return ShareablePaymentRow(
      tilePadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      title: '${isBtcTx ? 'BTC ' : ''}${texts.payment_details_sheet_tx_id_label}',
      titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
        fontSize: 18.0,
        color: Colors.white,
      ),
      sharedValue: txId,
      isURL: true,
      urlValue: BlockchainExplorerService.formatTransactionUrl(
        mempoolInstance: isBtcTx
            ? NetworkConstants.defaultBitcoinMempoolInstance
            : NetworkConstants.defaultLiquidMempoolInstance,
        txid: txId,
        unblindingData: unblindingData,
      ),
    );
  }
}
