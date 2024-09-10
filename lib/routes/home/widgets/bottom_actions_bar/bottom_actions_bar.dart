import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/receive_options_bottom_sheet.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/send_options_bottom_sheet.dart';

import 'bottom_action_item.dart';

class BottomActionsBar extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;

  const BottomActionsBar(
    this.firstPaymentItemKey, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final actionsGroup = AutoSizeGroup();

    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SendOptions(
              firstPaymentItemKey: firstPaymentItemKey,
              actionsGroup: actionsGroup,
            ),
            Container(width: 64),
            ReceiveOptions(
              firstPaymentItemKey: firstPaymentItemKey,
              actionsGroup: actionsGroup,
            )
          ],
        ),
      ),
    );
  }
}

class SendOptions extends StatelessWidget {
  final GlobalKey<State<StatefulWidget>> firstPaymentItemKey;
  final AutoSizeGroup actionsGroup;

  const SendOptions({
    super.key,
    required this.firstPaymentItemKey,
    required this.actionsGroup,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BottomActionItem(
      onPress: () => showModalBottomSheet(
        context: context,
        builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).appBarTheme.systemOverlayStyle!.copyWith(
                  systemNavigationBarColor: Theme.of(context).canvasColor,
                ),
            child: SafeArea(
              child: SendOptionsBottomSheet(
                firstPaymentItemKey: firstPaymentItemKey,
              ),
            ),
          );
        },
      ),
      group: actionsGroup,
      text: texts.bottom_action_bar_send,
      iconAssetPath: "assets/icons/send-action.png",
    );
  }
}

class ReceiveOptions extends StatelessWidget {
  final GlobalKey<State<StatefulWidget>> firstPaymentItemKey;
  final AutoSizeGroup actionsGroup;

  const ReceiveOptions({
    super.key,
    required this.firstPaymentItemKey,
    required this.actionsGroup,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    return BottomActionItem(
      onPress: () => showModalBottomSheet(
        context: context,
        builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).appBarTheme.systemOverlayStyle!.copyWith(
                  systemNavigationBarColor: Theme.of(context).canvasColor,
                ),
            child: SafeArea(
              child: ReceiveOptionsBottomSheet(
                firstPaymentItemKey: firstPaymentItemKey,
              ),
            ),
          );
        },
      ),
      group: actionsGroup,
      text: texts.bottom_action_bar_receive,
      iconAssetPath: "assets/icons/receive-action.png",
    );
  }
}
