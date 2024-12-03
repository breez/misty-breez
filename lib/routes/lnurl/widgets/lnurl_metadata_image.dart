import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class LNURLMetadataImage extends StatelessWidget {
  final String? base64String;

  const LNURLMetadataImage({
    super.key,
    this.base64String,
  });

  @override
  Widget build(BuildContext context) {
    const double imageSize = 128.0;

    final Uint8List? imageBytes = base64String?.isNotEmpty == true ? base64Decode(base64String!) : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: imageSize,
        minWidth: imageSize,
        maxHeight: imageSize,
        maxWidth: imageSize,
      ),
      child: imageBytes != null && imageBytes.isNotEmpty
          ? Image.memory(
              imageBytes,
              width: imageSize,
              fit: BoxFit.cover,
            )
          : Image.asset(
              'assets/icons/app_icon.png',
              width: imageSize,
              fit: BoxFit.cover,
            ),
    );
  }
}
