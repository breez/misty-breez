import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/home/home.dart';
import 'package:l_breez/routes/receive_payment/receive_payment.dart';
import 'package:l_breez/theme/theme.dart';

class ReceiveOptionsBottomSheet extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;

  const ReceiveOptionsBottomSheet({required this.firstPaymentItemKey, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 8.0),
        ListTile(
          leading: const BottomActionItemImage(
            iconAssetPath: 'assets/icons/ln_address.png',
          ),
          title: Text(
            texts.bottom_action_bar_ln_address,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final NavigatorState navigatorState = Navigator.of(context);
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
            iconAssetPath: 'assets/icons/paste.png',
          ),
          title: Text(
            texts.bottom_action_bar_receive_invoice,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final NavigatorState navigatorState = Navigator.of(context);
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
            iconAssetPath: 'assets/icons/bitcoin.png',
          ),
          title: Text(
            texts.bottom_action_bar_receive_btc_address,
            style: bottomSheetTextStyle,
          ),
          onTap: () {
            final NavigatorState navigatorState = Navigator.of(context);
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
