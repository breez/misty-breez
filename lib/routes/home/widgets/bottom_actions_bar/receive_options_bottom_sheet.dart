import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;

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
            style: theme.bottomSheetTextStyle,
          ),
          onTap: () {
            final navigatorState = Navigator.of(context);
            navigatorState.pop();
            navigatorState.pushNamed("/create_invoice");
          },
        ),
        const SizedBox(height: 8.0),
        ListTile(
          leading: const BottomActionItemImage(
            iconAssetPath: "src/icon/bitcoin.png",
          ),
          title: Text(
            texts.bottom_action_bar_receive_btc_address,
            style: theme.bottomSheetTextStyle,
          ),
          onTap: () {
            final navigatorState = Navigator.of(context);
            navigatorState.pop();
            navigatorState.pushNamed("/receive_chainswap");
          },
        ),
      ],
    );
  }
}
