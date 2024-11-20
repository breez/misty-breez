import 'package:flutter/material.dart';

class BottomActionItemImage extends StatelessWidget {
  final String iconAssetPath;
  final bool enabled;

  const BottomActionItemImage({
    required this.iconAssetPath,
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Image(
      image: AssetImage(
        iconAssetPath,
      ),
      color: enabled ? Colors.white : themeData.disabledColor,
      fit: BoxFit.contain,
      width: 24.0,
      height: 24.0,
    );
  }
}
