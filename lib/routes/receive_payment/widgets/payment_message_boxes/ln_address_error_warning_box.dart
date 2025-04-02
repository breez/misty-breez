import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

/// Warning box for LnAddressState errors
class LnAddressErrorWarningBox extends StatelessWidget {
  const LnAddressErrorWarningBox({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final BreezTranslations texts = context.texts();

    return BlocBuilder<LnAddressCubit, LnAddressState>(
      builder: (BuildContext context, LnAddressState state) {
        if (!state.hasError) {
          // Redirect to Lightning Address Page after LnAddressState error is resolved
          Future<void>.microtask(() {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(
                ReceivePaymentPage.routeName,
                arguments: ReceiveLightningAddressPage.pageIndex,
              );
            }
          });
          return const SizedBox.shrink();
        }

        final String errorMessage = ExceptionHandler.extractMessage(state.error!, texts);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              final LnAddressCubit lnAddressCubit = context.read<LnAddressCubit>();
              lnAddressCubit.setupLightningAddress(isRecover: true);
            },
            child: WarningBox(
              boxPadding: EdgeInsets.zero,
              backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
              contentPadding: const EdgeInsets.all(16.0),
              child: (state.isLoading)
                  ? const CenteredLoader()
                  : RichText(
                      text: TextSpan(
                        text: errorMessage,
                        style: themeData.textTheme.bodyLarge?.copyWith(
                          color: themeData.colorScheme.error,
                        ),
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
