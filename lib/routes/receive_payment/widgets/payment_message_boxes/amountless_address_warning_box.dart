import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class AmountlessBtcAddressWarningBox extends StatelessWidget {
  const AmountlessBtcAddressWarningBox({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<AmountlessBtcCubit, AmountlessBtcState>(
      builder: (BuildContext context, AmountlessBtcState state) {
        if (!state.hasError) {
          // Redirect to Amountless BTC Address Page after AmountlessBtcState error is resolved
          Future<void>.microtask(() {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(ReceivePaymentPage.routeName);
            }
          });
          return const SizedBox.shrink();
        }

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
                  text: ExceptionHandler.extractMessage(
                    state.error!,
                    texts,
                    defaultErrorMsg: 'Failed to generate amountless Bitcoin address.',
                  ),
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
      },
    );
  }
}
