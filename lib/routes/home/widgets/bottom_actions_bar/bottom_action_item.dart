import 'package:auto_size_text/auto_size_text.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:flutter/material.dart';

class BottomActionItem extends StatelessWidget {
  final String text;
  final AutoSizeGroup group;
  final String iconAssetPath;
  final Function() onPress;
  final Alignment minimizedAlignment;

  const BottomActionItem({
    super.key,
    required this.text,
    required this.group,
    required this.iconAssetPath,
    required this.onPress,
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
          style: theme.bottomAppBarBtnStyle.copyWith(
            fontSize: MediaQuery.of(context).textScaler.scale(13.5),
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
