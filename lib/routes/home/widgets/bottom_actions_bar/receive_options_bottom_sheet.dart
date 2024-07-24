import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/chainswap/receive/receive_chainswap_page.dart';
import 'package:l_breez/routes/create_invoice/create_invoice_page.dart';
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
            iconAssetPath: "src/icon/paste.png",
          ),
          title: Text(
            texts.bottom_action_bar_receive_invoice,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final navigatorState = Navigator.of(context);
            navigatorState.pop();
            navigatorState.pushNamed(CreateInvoicePage.routeName);
          },
        ),
        Divider(
          height: 0.0,
          color: Colors.white.withOpacity(0.2),
          indent: 72.0,
        ),
        ListTile(
          leading: const BottomActionItemImage(
            iconAssetPath: "src/icon/bitcoin.png",
          ),
          title: Text(
            texts.bottom_action_bar_receive_btc_address,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final navigatorState = Navigator.of(context);
            navigatorState.pop();
            navigatorState.pushNamed(ReceiveChainSwapPage.routeName);
          },
        ),
      ],
    );
  }
}
