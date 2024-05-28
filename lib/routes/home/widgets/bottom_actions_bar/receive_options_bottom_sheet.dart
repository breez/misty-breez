import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:flutter/material.dart';

import 'bottom_action_item_image.dart';

class ReceiveOptionsBottomSheet extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;

  const ReceiveOptionsBottomSheet({
    super.key,
    required this.firstPaymentItemKey,
  });

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
          onTap: () => _push(context, "/create_invoice"),
        ),
      ],
    );
  }

  void _push(BuildContext context, String route) {
    final navigatorState = Navigator.of(context);
    navigatorState.pop();
    navigatorState.pushNamed(route);
  }
}
