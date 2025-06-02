import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:shimmer/shimmer.dart';

class PlaceholderPaymentItem extends StatelessWidget {
  const PlaceholderPaymentItem({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    final CustomData customData = themeData.customData;
    final Color paymentListBgColor = customData.paymentListBgColor;
    return Shimmer.fromColors(
      baseColor: paymentListBgColor,
      highlightColor: customData.paymentListBgColor.withValues(alpha: .5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            color: themeData.customData.paymentListBgColor,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Container(
                    height: 72.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          offset: const Offset(0.5, 0.5),
                          blurRadius: 5.0,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.bolt_rounded, color: Color(0xb3303234)),
                    ),
                  ),
                  title: Transform.translate(
                    offset: const Offset(-8, 0),
                    child: Text(
                      '',
                      style: themeData.paymentItemTitleTextStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  subtitle: Transform.translate(
                    offset: const Offset(-8, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[Text('', style: themeData.paymentItemSubtitleTextStyle)],
                    ),
                  ),
                  trailing: SizedBox(
                    height: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text('', style: themeData.paymentItemAmountTextStyle),
                        Text('', style: themeData.paymentItemFeeTextStyle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
