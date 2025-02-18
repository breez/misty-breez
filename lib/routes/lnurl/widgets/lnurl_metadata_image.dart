import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class LNURLMetadataImage extends StatelessWidget {
  final String base64String;
  final double imageSize;

  const LNURLMetadataImage({
    required this.base64String,
    this.imageSize = 128,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List imageBytes = base64Decode(base64String);
    if (imageBytes.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: imageSize,
        minWidth: imageSize,
        maxHeight: imageSize,
        maxWidth: imageSize,
      ),
      child: Image.memory(
        imageBytes,
        width: imageSize,
        fit: BoxFit.cover,
      ),
    );
  }
}
