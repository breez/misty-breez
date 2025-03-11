import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/widgets/widgets.dart';

class RefundConfirmationButton extends StatelessWidget {
  final RefundRequest req;

  const RefundConfirmationButton({required this.req, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return SingleButtonBottomBar(
      text: texts.sweep_all_coins_action_confirm,
      onPressed: () => _refund(context),
    );
  }

  Future<void> _refund(BuildContext context) async {
    final RefundCubit refundCubit = context.read<RefundCubit>();

    final NavigatorState navigator = Navigator.of(context);
    final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);
    try {
      await showProcessingPaymentSheet(
        context,
        promptError: true,
        popToHomeOnCompletion: true,
        isBroadcast: true,
        paymentFunc: () async => await refundCubit.refund(req: req),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
    } finally {
      if (loaderRoute.isActive) {
        navigator.removeRoute(loaderRoute);
      }
    }
  }
}
