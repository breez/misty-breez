import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class AmountlessBtcAddressErrorView extends StatelessWidget {
  final Object error;

  const AmountlessBtcAddressErrorView({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final AmountlessBtcCubit amountlessBtcCubit = context.read<AmountlessBtcCubit>();
          amountlessBtcCubit.generateAmountlessAddress();
        },
        child: WarningBox(
          boxPadding: EdgeInsets.zero,
          backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
          contentPadding: const EdgeInsets.all(16.0),
          child: RichText(
            text: TextSpan(
              text: ExceptionHandler.extractMessage(error, texts),
              style: themeData.textTheme.bodyLarge?.copyWith(color: themeData.colorScheme.error),
              children: <InlineSpan>[
                TextSpan(
                  text: '\n\nTap here to retry',
                  style: themeData.textTheme.titleLarge?.copyWith(
                    color: themeData.colorScheme.error.withValues(alpha: .7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
