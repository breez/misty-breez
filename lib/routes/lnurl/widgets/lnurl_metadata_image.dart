import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class LNURLMetadataImage extends StatelessWidget {
  final String base64String;

  const LNURLMetadataImage({
    required this.base64String,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double imageSize = 128.0;

    final Uint8List imageBytes = base64Decode(base64String);
    if (imageBytes.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
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
