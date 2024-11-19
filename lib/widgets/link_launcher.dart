import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/utils/external_browser.dart';

class LinkLauncher extends StatelessWidget {
  final double iconSize;
  final TextStyle? textStyle;
  final String? linkTitle;
  final String? linkName;
  final String linkAddress;
  final Function() onCopy;

  const LinkLauncher({
    required this.linkAddress,
    required this.onCopy,
    super.key,
    this.linkName,
    this.textStyle,
    this.linkTitle,
    this.iconSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final TextStyle style = textStyle ?? DefaultTextStyle.of(context).style;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                linkTitle ?? texts.link_launcher_title,
                textAlign: TextAlign.start,
                style: textStyle,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerRight,
                      iconSize: iconSize,
                      color: style.color,
                      icon: const Icon(Icons.launch),
                      onPressed: () async {
                        await launchLinkOnExternalBrowser(
                          context,
                          linkAddress: linkAddress,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(),
                child: GestureDetector(
                  onTap: onCopy,
                  child: Text(
                    linkName ?? texts.link_launcher_link_name,
                    style: style,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.clip,
                    maxLines: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
