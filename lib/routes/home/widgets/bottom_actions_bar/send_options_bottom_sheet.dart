import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_page.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/bottom_action_item_image.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/enter_payment_info_page.dart';
import 'package:l_breez/theme/theme.dart';

class SendOptionsBottomSheet extends StatefulWidget {
  final GlobalKey firstPaymentItemKey;

  const SendOptionsBottomSheet({super.key, required this.firstPaymentItemKey});

  @override
  State<SendOptionsBottomSheet> createState() => _SendOptionsBottomSheetState();
}

class _SendOptionsBottomSheetState extends State<SendOptionsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, account) {
        final hasBalance = account.hasBalance;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8.0),
            ListTile(
              enabled: hasBalance,
              leading: BottomActionItemImage(
                iconAssetPath: "assets/icons/paste.png",
                enabled: hasBalance,
              ),
              title: Text(
                texts.bottom_action_bar_enter_payment_info,
                style: bottomSheetTextStyle,
              ),
              onTap: () {
                final navigatorState = Navigator.of(context);
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
                iconAssetPath: "assets/icons/bitcoin.png",
                enabled: hasBalance,
              ),
              title: Text(
                texts.bottom_action_bar_send_btc_address,
                style: bottomSheetTextStyle,
              ),
              onTap: () {
                final navigatorState = Navigator.of(context);
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
