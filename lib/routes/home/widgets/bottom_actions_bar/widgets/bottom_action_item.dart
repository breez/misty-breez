import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';

class BottomActionItem extends StatelessWidget {
  final String text;
  final AutoSizeGroup group;
  final String iconAssetPath;
  final Function() onPress;
  final Alignment minimizedAlignment;

  const BottomActionItem({
    required this.text,
    required this.group,
    required this.iconAssetPath,
    required this.onPress,
    super.key,
    this.minimizedAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
        onPressed: onPress,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: bottomAppBarBtnStyle.copyWith(
            fontSize: MediaQuery.of(context).textScaler.scale(13.5),
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
