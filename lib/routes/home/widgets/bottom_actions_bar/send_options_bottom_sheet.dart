import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/bottom_action_item_image.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/enter_payment_info_dialog.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:flutter/material.dart';

class SendOptionsBottomSheet extends StatefulWidget {
  final GlobalKey firstPaymentItemKey;

  const SendOptionsBottomSheet({
    super.key,
    required this.firstPaymentItemKey,
  });

  @override
  State<SendOptionsBottomSheet> createState() => _SendOptionsBottomSheetState();
}

class _SendOptionsBottomSheetState extends State<SendOptionsBottomSheet> {
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
            texts.bottom_action_bar_paste_invoice,
            style: theme.bottomSheetTextStyle,
          ),
          onTap: () => _showEnterPaymentInfoDialog(context, widget.firstPaymentItemKey),
        ),
      ],
    );
  }

  Future<void> _showEnterPaymentInfoDialog(
    BuildContext context,
    GlobalKey<State<StatefulWidget>> firstPaymentItemKey,
  ) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => EnterPaymentInfoDialog(
        paymentItemKey: firstPaymentItemKey,
      ),
    );
  }
}
