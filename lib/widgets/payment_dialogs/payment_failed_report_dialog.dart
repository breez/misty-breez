import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';

// TODO: Liquid - This file is unused - Re-use after payment report API is implemented on Liquid SDK
class PaymentFailedReportDialog extends StatefulWidget {
  const PaymentFailedReportDialog({super.key});

  @override
  PaymentFailedReportDialogState createState() {
    return PaymentFailedReportDialogState();
  }
}

class PaymentFailedReportDialogState extends State<PaymentFailedReportDialog> {
  bool _doNotAskAgain = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    return Theme(
      data: themeData.copyWith(
        unselectedWidgetColor: themeData.canvasColor,
      ),
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24.0, 22.0, 0.0, 16.0),
        title: Text(
          texts.payment_failed_report_dialog_title,
          style: themeData.dialogTheme.titleTextStyle,
        ),
        contentPadding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 12.0),
              child: Text(
                texts.payment_failed_report_dialog_message,
                style: themeData.primaryTextTheme.displaySmall?.copyWith(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Theme(
                    data: themeData.copyWith(
                      unselectedWidgetColor: themeData.textTheme.labelLarge?.color,
                    ),
                    child: Checkbox(
                      activeColor: themeData.canvasColor,
                      value: _doNotAskAgain,
                      onChanged: (doNotAskAgain) {
                        setState(() {
                          _doNotAskAgain = doNotAskAgain ?? false;
                        });
                      },
                    ),
                  ),
                  Text(
                    texts.payment_failed_report_dialog_do_not_ask_again,
                    style: themeData.primaryTextTheme.displaySmall?.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, PaymentFailedReportDialogResult(false, _doNotAskAgain));
            },
            child: Text(
              texts.payment_failed_report_dialog_action_no,
              style: themeData.primaryTextTheme.labelLarge,
            ),
          ),
          SimpleDialogOption(
            onPressed: (() async {
              Navigator.pop(context, PaymentFailedReportDialogResult(true, _doNotAskAgain));
            }),
            child: Text(
              texts.payment_failed_report_dialog_action_yes,
              style: themeData.primaryTextTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentFailedReportDialogResult {
  final bool report;
  final bool doNotAskAgain;

  const PaymentFailedReportDialogResult(this.report, this.doNotAskAgain);

  @override
  String toString() {
    return 'PaymentFailedReportDialogResult{report: $report, doNotAskAgain: $doNotAskAgain}';
  }
}
