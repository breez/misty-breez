import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/home_page.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/error_dialog.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class SendChainSwapButton extends StatelessWidget {
  final String recipientAddress;
  final PreparePayOnchainResponse preparePayOnchainResponse;

  const SendChainSwapButton({
    super.key,
    required this.recipientAddress,
    required this.preparePayOnchainResponse,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return SingleButtonBottomBar(
      text: texts.sweep_all_coins_action_confirm,
      onPressed: () => _payOnchain(context),
    );
  }

  Future _payOnchain(BuildContext context) async {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final chainSwapCubit = context.read<ChainSwapCubit>();

    final navigator = Navigator.of(context);
    var loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);
    try {
      final req = PayOnchainRequest(address: recipientAddress, prepareRes: preparePayOnchainResponse);
      await chainSwapCubit.payOnchain(req: req);
      navigator.pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);
    } catch (e) {
      navigator.pop(loaderRoute);
      if (!context.mounted) return;
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
