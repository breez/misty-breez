import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

class RefundItemAction extends StatefulWidget {
  final RefundableSwap swapInfo;

  const RefundItemAction(this.swapInfo, {super.key});

  @override
  State<RefundItemAction> createState() => _RefundItemActionState();
}

class _RefundItemActionState extends State<RefundItemAction> {
  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 36.0,
            width: 145.0,
            child: SubmitButton(
              texts.get_refund_action_broadcasted,
              () {
                Navigator.of(context).pushNamed(
                  RefundPage.routeName,
                  arguments: widget.swapInfo,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
