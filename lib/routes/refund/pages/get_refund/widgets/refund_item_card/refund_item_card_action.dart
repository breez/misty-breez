import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';

class RefundItemCardAction extends StatelessWidget {
  final RefundableSwap refundableSwap;
  final String lastRefundTxId;

  const RefundItemCardAction({
    required this.refundableSwap,
    required this.lastRefundTxId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    final bool allowRebroadcast = context.select<RefundCubit, bool>(
      (RefundCubit cubit) => cubit.state.rebroadcastEnabled,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            backgroundColor: themeData.primaryColor,
            elevation: 0.0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          ),
          onPressed: lastRefundTxId.isEmpty || allowRebroadcast
              ? () {
                  Navigator.of(context).pushNamed(
                    RefundPage.routeName,
                    arguments: refundableSwap,
                  );
                }
              : null,
          child: Text(
            lastRefundTxId.isNotEmpty
                ? allowRebroadcast
                    // TODO(erdemyerebasmaz): Add message to Breez-Translations
                    ? 'REBROADCAST'
                    : texts.get_refund_action_broadcasted
                : texts.get_refund_action_continue,
            style: themeData.textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}
