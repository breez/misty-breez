import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/utils/external_browser.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class ShareablePaymentRow extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final String sharedValue;
  final String? urlValue;
  final bool isURL;
  final bool isExpanded;
  final TextStyle? titleTextStyle;
  final TextStyle? childrenTextStyle;
  final EdgeInsets? iconPadding;
  final EdgeInsets? tilePadding;
  final EdgeInsets? childrenPadding;
  final Color? dividerColor;
  final AutoSizeGroup? labelAutoSizeGroup;
  final AutoSizeGroup? valueAutoSizeGroup;

  const ShareablePaymentRow({
    required this.title,
    required this.sharedValue,
    super.key,
    this.titleWidget,
    this.urlValue,
    this.isURL = false,
    this.isExpanded = false,
    this.titleTextStyle,
    this.childrenTextStyle,
    this.iconPadding,
    this.tilePadding,
    this.childrenPadding,
    this.dividerColor,
    this.labelAutoSizeGroup,
    this.valueAutoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Theme(
      data: themeData.copyWith(
        dividerColor: dividerColor ?? themeData.colorScheme.surface,
      ),
      child: ExpansionTile(
        dense: true,
        iconColor: isExpanded ? Colors.transparent : Colors.white,
        collapsedIconColor: Colors.white,
        initiallyExpanded: isExpanded,
        tilePadding: tilePadding,
        title: titleWidget ??
            AutoSizeText(
              title,
              style: titleTextStyle ?? themeData.primaryTextTheme.headlineMedium,
              maxLines: 2,
              group: labelAutoSizeGroup,
            ),
        children: <Widget>[
          WarningBox(
            boxPadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            backgroundColor: themeData.primaryColorLight.withOpacity(0.1),
            borderColor: themeData.primaryColorLight.withOpacity(0.7),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: childrenPadding ?? EdgeInsets.zero,
                    child: GestureDetector(
                      onTap: isURL
                          ? () => launchLinkOnExternalBrowser(context, linkAddress: urlValue ?? sharedValue)
                          : null,
                      child: Text(
                        sharedValue,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.clip,
                        maxLines: 4,
                        style: childrenTextStyle ??
                            themeData.primaryTextTheme.displaySmall!.copyWith(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.156,
                            ),
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
                      children: <Widget>[
                        IconButton(
                          alignment: Alignment.centerRight,
                          padding: iconPadding ?? const EdgeInsets.only(right: 8.0),
                          tooltip: texts.payment_details_dialog_copy_action(title),
                          iconSize: 20.0,
                          color: Colors.white,
                          icon: const Icon(
                            IconData(0xe90b, fontFamily: 'icomoon'),
                          ),
                          onPressed: () {
                            ServiceInjector().deviceClient.setClipboardText(sharedValue);
                            Navigator.pop(context);
                            showFlushbar(
                              context,
                              message: texts.payment_details_dialog_copied(
                                title.substring(0, title.length - 1),
                              ),
                              duration: const Duration(seconds: 4),
                            );
                          },
                        ),
                        IconButton(
                          padding: iconPadding ?? const EdgeInsets.only(right: 8.0),
                          tooltip: texts.payment_details_dialog_share_transaction,
                          iconSize: 20.0,
                          color: Colors.white,
                          icon: const Icon(Icons.share),
                          onPressed: () => Share.share(sharedValue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
