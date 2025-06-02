import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class DestinationInformation extends StatefulWidget {
  final String lnAddress;

  const DestinationInformation({required this.lnAddress, super.key});

  @override
  DestinationInformationState createState() => DestinationInformationState();
}

class DestinationInformationState extends State<DestinationInformation> {
  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        // TODO(erdemyerebasmaz): Display the dropdown menu in a static place that does not obstruct LN Address
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final Offset offset = details.globalPosition;

        showMenu(
          context: context,
          color: themeData.customData.paymentListBgColorLight,
          position: RelativeRect.fromRect(Rect.fromPoints(offset, offset), Offset.zero & overlay.size),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          items: <PopupMenuItem<String>>[
            PopupMenuItem<String>(
              // TODO(erdemyerebasmaz): Replace with const var
              value: 'customize',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.edit),
                  const SizedBox(width: 8.0),
                  Text(texts.update_ln_address_username_title),
                ],
              ),
            ),
          ],
        ).then((String? value) {
          // TODO(erdemyerebasmaz): Replace with const var
          if (value == 'customize') {
            if (context.mounted) {
              showModalBottomSheet(
                context: context,
                backgroundColor: themeData.customData.paymentListBgColor,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                isScrollControlled: true,
                builder: (BuildContext context) =>
                    UpdateLnAddressUsernameBottomSheet(lnAddress: widget.lnAddress),
              );
            }
          }
        });
      },
      child: WarningBox(
        boxPadding: const EdgeInsets.only(bottom: 24.0),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        borderColor: Colors.transparent,
        backgroundColor: Theme.of(context).canvasColor,
        child: Center(
          child: AutoSizeText(
            widget.lnAddress,
            style: themeData.primaryTextTheme.bodyMedium!.copyWith(fontSize: 18.0),
            maxLines: 1,
            minFontSize: MinFontSize(context).minFontSize,
            stepGranularity: 0.1,
          ),
        ),
      ),
    );
  }
}
