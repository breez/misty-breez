import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/bottom_action_item_image.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/enter_payment_info_page.dart';
import 'package:l_breez/routes/send_payment/chainswap/chainswap.dart';
import 'package:l_breez/theme/theme.dart';

class SendOptionsBottomSheet extends StatefulWidget {
  final GlobalKey firstPaymentItemKey;

  const SendOptionsBottomSheet({required this.firstPaymentItemKey, super.key});

  @override
  State<SendOptionsBottomSheet> createState() => _SendOptionsBottomSheetState();
}

class _SendOptionsBottomSheetState extends State<SendOptionsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (BuildContext context, AccountState account) {
        final bool hasBalance = account.hasBalance;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8.0),
            ListTile(
              enabled: hasBalance,
              leading: BottomActionItemImage(
                iconAssetPath: 'assets/icons/paste.png',
                enabled: hasBalance,
              ),
              title: Text(
                texts.bottom_action_bar_enter_payment_info,
                style: bottomSheetTextStyle,
              ),
              onTap: () {
                final NavigatorState navigatorState = Navigator.of(context);
                navigatorState.pop();
                navigatorState.pushNamed(EnterPaymentInfoPage.routeName);
              },
            ),
            Divider(
              height: 0.0,
              color: Colors.white.withOpacity(0.2),
              indent: 72.0,
            ),
            ListTile(
              enabled: hasBalance,
              leading: BottomActionItemImage(
                iconAssetPath: 'assets/icons/bitcoin.png',
                enabled: hasBalance,
              ),
              title: Text(
                texts.bottom_action_bar_send_btc_address,
                style: bottomSheetTextStyle,
              ),
              onTap: () {
                final NavigatorState navigatorState = Navigator.of(context);
                navigatorState.pop();
                navigatorState.pushNamed(SendChainSwapPage.routeName);
              },
            ),
          ],
        );
      },
    );
  }
}
