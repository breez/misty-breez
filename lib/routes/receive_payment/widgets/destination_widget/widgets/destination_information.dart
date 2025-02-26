import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/widgets/widgets.dart';
import 'package:l_breez/widgets/widgets.dart';

class DestinationInformation extends StatefulWidget {
  final String lnAddress;

  const DestinationInformation({
    required this.lnAddress,
    super.key,
  });

  @override
  DestinationInformationState createState() => DestinationInformationState();
}

class DestinationInformationState extends State<DestinationInformation> {
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        // TODO(erdemyerebasmaz): Display the dropdown menu in a static place that does not obstruct LN Address
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final Offset offset = details.globalPosition;

        showMenu(
          context: context,
          color: themeData.colorScheme.surface,
          position: RelativeRect.fromRect(
            Rect.fromPoints(offset, offset),
            Offset.zero & overlay.size,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          items: <PopupMenuItem<String>>[
            const PopupMenuItem<String>(
              // TODO(erdemyerebasmaz): Replace with const var
              value: 'customize',
              child: Row(
                children: <Widget>[
                  Icon(Icons.edit),
                  SizedBox(
                    width: 8.0,
                  ),
                  // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
                  Text('Customize Address'),
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
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                isScrollControlled: true,
                builder: (BuildContext context) => UpdateLnAddressUsernameBottomSheet(
                  lnAddress: widget.lnAddress,
                ),
              );
            }
          }
        });
      },
      child: WarningBox(
        boxPadding: const EdgeInsets.only(bottom: 24.0),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        borderColor: Colors.transparent,
        backgroundColor: Theme.of(context).canvasColor,
        child: Center(
          child: Text(
            widget.lnAddress,
            style: themeData.primaryTextTheme.bodyMedium!.copyWith(fontSize: 18.0),
          ),
        ),
      ),
    );
  }
}
