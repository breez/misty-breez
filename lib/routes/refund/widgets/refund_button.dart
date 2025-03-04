import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/exceptions/exception_handler.dart';
import 'package:l_breez/widgets/widgets.dart';

class RefundButton extends StatelessWidget {
  final RefundRequest req;

  const RefundButton({required this.req, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return SingleButtonBottomBar(
      text: texts.sweep_all_coins_action_confirm,
      onPressed: () => _refund(context),
    );
  }

  Future<void> _refund(BuildContext context) async {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final RefundCubit refundCubit = context.read<RefundCubit>();

    final NavigatorState navigator = Navigator.of(context);
    final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);
    try {
      await refundCubit.refund(req: req);

      if (!context.mounted) {
        return;
      }

      navigator.popUntil(
        (Route<dynamic> route) => route.settings.name == Home.routeName,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      promptError(
        context,
        title: 'Refund Failed',
        body: Text(
          ExceptionHandler.extractMessage(e, texts),
          style: themeData.dialogTheme.contentTextStyle,
        ),
      );
    } finally {
      if (loaderRoute.isActive) {
        navigator.removeRoute(loaderRoute);
      }
    }
  }
}
