import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/services/injector.dart';
import 'package:l_breez/utils/external_browser.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareablePaymentRow extends StatelessWidget {
  final String title;
  final String sharedValue;
  final bool isURL;
  final bool isExpanded;
  final TextStyle? titleTextStyle;
  final TextStyle? childrenTextStyle;
  final EdgeInsets? iconPadding;
  final EdgeInsets? tilePadding;
  final EdgeInsets? childrenPadding;
  final AutoSizeGroup? labelAutoSizeGroup;
  final AutoSizeGroup? valueAutoSizeGroup;

  const ShareablePaymentRow({
    super.key,
    required this.title,
    required this.sharedValue,
    this.isURL = false,
    this.isExpanded = false,
    this.titleTextStyle,
    this.childrenTextStyle,
    this.iconPadding,
    this.tilePadding,
    this.childrenPadding,
    this.labelAutoSizeGroup,
    this.valueAutoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final color = themeData.primaryTextTheme.labelLarge!.color!;

    return Theme(
      data: themeData.copyWith(
        dividerColor: themeData.colorScheme.surface,
      ),
      child: ExpansionTile(
        iconColor: isExpanded ? Colors.transparent : color,
        collapsedIconColor: color,
        initiallyExpanded: isExpanded,
        tilePadding: tilePadding,
        title: AutoSizeText(
          title,
          style: titleTextStyle ?? themeData.primaryTextTheme.headlineMedium,
          maxLines: 2,
          group: labelAutoSizeGroup,
        ),
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: childrenPadding ?? const EdgeInsets.only(left: 16.0, right: 0.0),
                  child: GestureDetector(
                    onTap:
                        isURL ? () => launchLinkOnExternalBrowser(context, linkAddress: sharedValue) : null,
                    child: Text(
                      sharedValue,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.clip,
                      maxLines: 4,
                      style: childrenTextStyle ??
                          themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 10),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 0,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        alignment: Alignment.centerRight,
                        padding: iconPadding ?? const EdgeInsets.only(right: 8.0),
                        tooltip: texts.payment_details_dialog_copy_action(title),
                        iconSize: 16.0,
                        color: color,
                        icon: const Icon(
                          IconData(0xe90b, fontFamily: 'icomoon'),
                        ),
                        onPressed: () {
                          ServiceInjector().device.setClipboardText(sharedValue);
                          Navigator.pop(context);
                          showFlushbar(
                            context,
                            message: texts.payment_details_dialog_copied(title),
                            duration: const Duration(seconds: 4),
                          );
                        },
                      ),
                      IconButton(
                        padding: iconPadding ?? const EdgeInsets.only(right: 8.0),
                        tooltip: texts.payment_details_dialog_share_transaction,
                        iconSize: 16.0,
                        color: color,
                        icon: const Icon(Icons.share),
                        onPressed: () => Share.share(sharedValue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
