import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class CollapsibleListItem extends StatelessWidget {
  final String title;
  final String? sharedValue;
  final AutoSizeGroup? labelGroup;
  final TextStyle userStyle;

  const CollapsibleListItem({
    required this.title,
    required this.userStyle,
    super.key,
    this.sharedValue,
    this.labelGroup,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final BreezTranslations texts = context.texts();
    final TextTheme textTheme = themeData.primaryTextTheme;

    return ListTileTheme(
      contentPadding: EdgeInsets.zero,
      textColor: userStyle.color,
      iconColor: userStyle.color,
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: userStyle.color,
          collapsedIconColor: userStyle.color,
          title: AutoSizeText(
            title,
            style: textTheme.headlineMedium!.merge(userStyle),
            maxLines: 1,
            group: labelGroup,
          ),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      sharedValue ?? texts.collapsible_list_default_value,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.clip,
                      maxLines: 4,
                      style: textTheme.displaySmall!.copyWith(fontSize: 10).merge(userStyle),
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
                          padding: const EdgeInsets.only(right: 8.0),
                          tooltip: texts.collapsible_list_action_copy(title),
                          iconSize: 16.0,
                          color: userStyle.color ?? textTheme.labelLarge!.color!,
                          icon: const Icon(
                            IconData(0xe90b, fontFamily: 'icomoon'),
                          ),
                          onPressed: () {
                            ServiceInjector().deviceClient.setClipboardText(sharedValue!);
                            Navigator.pop(context);
                            showFlushbar(
                              context,
                              message: texts.collapsible_list_copied(title),
                              duration: const Duration(seconds: 4),
                            );
                          },
                        ),
                        IconButton(
                          padding: const EdgeInsets.only(right: 8.0),
                          iconSize: 16.0,
                          color: userStyle.color ?? textTheme.labelLarge!.color!,
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            if (sharedValue != null) {
                              Share.share(sharedValue!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
