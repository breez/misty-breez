import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';

class SendChainSwapButton extends StatelessWidget {
  final String recipientAddress;
  final PreparePayOnchainResponse preparePayOnchainResponse;

  const SendChainSwapButton({
    required this.recipientAddress,
    required this.preparePayOnchainResponse,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return SingleButtonBottomBar(
      text: texts.sweep_all_coins_action_confirm,
      onPressed: () => _payOnchain(context),
    );
  }

  Future<void> _payOnchain(BuildContext context) async {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final ChainSwapCubit chainSwapCubit = context.read<ChainSwapCubit>();

    final NavigatorState navigator = Navigator.of(context);
    final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);
    try {
      final PayOnchainRequest req = PayOnchainRequest(
        address: recipientAddress,
        prepareResponse: preparePayOnchainResponse,
      );
      await chainSwapCubit.payOnchain(req: req);
      navigator.pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);
    } catch (e) {
      navigator.pop(loaderRoute);
      if (!context.mounted) {
        return;
      }
      promptError(
        context,
        null,
        Text(
          extractExceptionMessage(e, texts),
          style: themeData.dialogTheme.contentTextStyle,
        ),
      );
    }
  }
}
