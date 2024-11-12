import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:shimmer/shimmer.dart';

class PlaceholderPaymentItem extends StatelessWidget {
  const PlaceholderPaymentItem({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final customData = themeData.customData;
    final paymentListBgColor = customData.paymentListBgColor;
    return Shimmer.fromColors(
      baseColor: paymentListBgColor,
      highlightColor: customData.paymentListBgColor.withOpacity(0.5),
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            color: themeData.customData.paymentListBgColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ListTile(
                  leading: Container(
                    height: 72.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0.5, 0.5),
                          blurRadius: 5.0,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.bolt_rounded,
                        color: Color(0xb3303234),
                      ),
                    ),
                  ),
                  title: Transform.translate(
                    offset: const Offset(-8, 0),
                    child: Text(
                      "",
                      style: themeData.paymentItemTitleTextStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  subtitle: Transform.translate(
                    offset: const Offset(-8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("", style: themeData.paymentItemSubtitleTextStyle),
                      ],
                    ),
                  ),
                  trailing: SizedBox(
                    height: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "",
                          style: themeData.paymentItemAmountTextStyle,
                        ),
                        Text(
                          "",
                          style: themeData.paymentItemFeeTextStyle,
                        ),
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
