import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/routes/create_invoice/widgets/successful_payment_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SuccessfulPaymentDialog extends StatelessWidget {
  final Function()? onPrint;

  const SuccessfulPaymentDialog({
    super.key,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.of(context).pop(),
      child: AlertDialog(
        title: onPrint != null
            ? Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: texts.successful_payment_print,
                  iconSize: 24.0,
                  color: themeData.appBarTheme.actionsIconTheme!.color,
                  icon: SvgPicture.asset(
                    "src/icon/printer.svg",
                    colorFilter: ColorFilter.mode(
                      themeData.appBarTheme.actionsIconTheme!.color!,
                      BlendMode.srcATop,
                    ),
                    fit: BoxFit.contain,
                    width: 24.0,
                    height: 24.0,
                  ),
                  onPressed: onPrint,
                ),
              )
            : const SizedBox(height: 40),
        titlePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
        content: const SuccessfulPaymentMessage(),
      ),
    );
  }
}
