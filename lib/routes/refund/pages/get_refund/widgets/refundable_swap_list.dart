import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/routes/routes.dart';

class RefundableSwapList extends StatelessWidget {
  final List<RefundableSwap> refundables;

  const RefundableSwapList({required this.refundables, super.key});

  @override
  Widget build(BuildContext context) {
    if (refundables.isEmpty) {
      final BreezTranslations texts = context.texts();

      return Center(child: Text(texts.get_refund_no_refundable_items));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: refundables.length,
      itemBuilder: (BuildContext context, int index) {
        return RefundItemCard(refundableSwap: refundables[index]);
      },
    );
  }
}
