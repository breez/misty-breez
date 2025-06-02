import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';

export 'widgets/widgets.dart';

final AutoSizeGroup actionsGroup = AutoSizeGroup();

class BottomActionsBar extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;

  const BottomActionsBar(this.firstPaymentItemKey, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            BottomActionItem(
              onPress: () {
                Navigator.of(context).pushNamed(EnterPaymentInfoPage.routeName);
              },
              group: actionsGroup,
              text: texts.bottom_action_bar_send,
              iconAssetPath: 'assets/icons/send-action.png',
            ),
            Container(width: 64),
            BottomActionItem(
              onPress: () {
                Navigator.of(context).pushNamed(ReceivePaymentPage.routeName);
              },
              group: actionsGroup,
              text: texts.bottom_action_bar_receive,
              iconAssetPath: 'assets/icons/receive-action.png',
            ),
          ],
        ),
      ),
    );
  }
}
