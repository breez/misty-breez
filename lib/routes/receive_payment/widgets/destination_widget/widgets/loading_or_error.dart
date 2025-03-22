import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class LoadingOrError extends StatelessWidget {
  final Object? error;

  const LoadingOrError({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (error == null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 310.0,
        child: Align(
          alignment: const Alignment(0, -0.33),
          child: SizedBox(
            height: 80.0,
            width: 80.0,
            child: CircularProgressIndicator(color: themeData.colorScheme.onSecondary),
          ),
        ),
      );
    }

    final BreezTranslations texts = context.texts();

    return ScrollableErrorMessageWidget(
      showIcon: true,
      title: '${texts.qr_code_dialog_warning_message_error}:',
      message: ExceptionHandler.extractMessage(error!, texts),
      padding: EdgeInsets.zero,
    );
  }
}
