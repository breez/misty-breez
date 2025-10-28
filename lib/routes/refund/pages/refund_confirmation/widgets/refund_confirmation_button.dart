import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

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
      return await showProcessingPaymentSheet(
        context,
        isBroadcast: true,
        paymentFunc: () async => await refundCubit.refund(req: req),
      ).then((dynamic result) {
        // Navigate to home after handling the result
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);

          // Payment timeout doesn't necessarily mean the payment failed.
          // We're popping to Home page to avoid user retries and duplicate payments.
          final ThemeData themeData = Theme.of(context);
          promptError(
            context,
            title: (result is PaymentError_PaymentTimeout)
                ? context.texts().unexpected_error_title
                : context.texts().payment_failed_report_dialog_title,
            body: Text(
              ExceptionHandler.extractMessage(result, context.texts()),
              style: themeData.dialogTheme.contentTextStyle,
            ),
          );
        }
      });
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
