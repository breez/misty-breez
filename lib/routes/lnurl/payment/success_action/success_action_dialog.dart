import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/routes/home/widgets/payments_list/dialog/shareable_payment_row.dart';
import 'package:flutter/material.dart';

class SuccessActionDialog extends StatefulWidget {
  final String message;
  final String? url;

  const SuccessActionDialog({super.key, required this.message, this.url});

  @override
  State<StatefulWidget> createState() {
    return SuccessActionDialogState();
  }
}

class SuccessActionDialogState extends State<SuccessActionDialog> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    return AlertDialog(
      title: Text(texts.ln_url_success_action_title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.url == null) Message(widget.message),
            if (widget.url != null) ...[
              ShareablePaymentRow(
                title: widget.message,
                sharedValue: widget.url!,
                isURL: true,
                isExpanded: true,
                titleTextStyle: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16),
                childrenTextStyle: themeData.primaryTextTheme.displaySmall!.copyWith(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.blue,
                ),
                iconPadding: EdgeInsets.zero,
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
      contentPadding: const EdgeInsets.only(top: 16.0, left: 32.0, right: 32.0),
      actions: [
        TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.transparent;
              }
              // Defer to the widget's default.
              return themeData.textTheme.labelLarge!.color!;
            }),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            texts.lnurl_withdraw_dialog_action_close,
            style: themeData.primaryTextTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class Message extends StatelessWidget {
  final String message;

  const Message(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 200,
          minWidth: double.infinity,
        ),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: AutoSizeText(
              message,
              style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16),
              textAlign: message.length > 40 && !message.contains("\n") ? TextAlign.start : TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }
}
