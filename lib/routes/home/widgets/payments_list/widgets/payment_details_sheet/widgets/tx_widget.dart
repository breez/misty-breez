import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

// TODO(erdemyerebasmaz): Liquid - This file is unused - Re-add for swap tx's after input parser is implemented
class TxWidget extends StatelessWidget {
  final String txURL;
  final String txID;
  final String? txLabel;
  final EdgeInsets? padding;

  const TxWidget({
    required this.txURL,
    required this.txID,
    super.key,
    this.txLabel,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    TextStyle textStyle = DefaultTextStyle.of(context).style;
    textStyle = textStyle.copyWith(
      fontSize: textStyle.fontSize! * 0.8,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: LinkLauncher(
            linkTitle: txLabel ?? texts.payment_details_dialog_transaction_label_default,
            textStyle: textStyle,
            linkName: txID,
            linkAddress: txURL,
            onCopy: () {
              ServiceInjector().deviceClient.setClipboardText(txID);
              showFlushbar(
                context,
                message: texts.payment_details_dialog_transaction_id_copied,
                duration: const Duration(seconds: 3),
              );
            },
          ),
        ),
      ],
    );
  }
}
