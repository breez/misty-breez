import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/receive_lightning_page.dart';
import 'package:l_breez/routes/receive_payment/ln_address/receive_lightning_address_page.dart';
import 'package:l_breez/routes/receive_payment/onchain/bitcoin_address/receive_bitcoin_address_payment_page.dart';
import 'package:l_breez/routes/receive_payment/receive_payment_page.dart';
import 'package:l_breez/theme/theme.dart';

import 'bottom_action_item_image.dart';

class ReceiveOptionsBottomSheet extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;

  const ReceiveOptionsBottomSheet({super.key, required this.firstPaymentItemKey});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8.0),
        ListTile(
          leading: const BottomActionItemImage(
            iconAssetPath: "assets/icons/ln_address.png",
          ),
          title: Text(
            texts.bottom_action_bar_ln_address,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final navigatorState = Navigator.of(context);
            navigatorState.pop();
            navigatorState.pushNamed(
              ReceivePaymentPage.routeName,
              arguments: ReceiveLightningAddressPage.pageIndex,
            );
          },
        ),
        Divider(
          height: 0.0,
          color: Colors.white.withOpacity(0.2),
          indent: 72.0,
        ),
        ListTile(
          leading: const BottomActionItemImage(
            iconAssetPath: "assets/icons/paste.png",
          ),
          title: Text(
            texts.bottom_action_bar_receive_invoice,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final navigatorState = Navigator.of(context);
            navigatorState.pop();
            navigatorState.pushNamed(
              ReceivePaymentPage.routeName,
              arguments: ReceiveLightningPaymentPage.pageIndex,
            );
          },
        ),
        Divider(
          height: 0.0,
          color: Colors.white.withOpacity(0.2),
          indent: 72.0,
        ),
        ListTile(
          leading: const BottomActionItemImage(
            iconAssetPath: "assets/icons/bitcoin.png",
          ),
          title: Text(
            texts.bottom_action_bar_receive_btc_address,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final navigatorState = Navigator.of(context);
            navigatorState.pop();
            navigatorState.pushNamed(
              ReceivePaymentPage.routeName,
              arguments: ReceiveBitcoinAddressPaymentPage.pageIndex,
            );
          },
        ),
      ],
    );
  }
}
