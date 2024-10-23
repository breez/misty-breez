import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/min_font_size.dart';

class LNURLMetadataText extends StatelessWidget {
  const LNURLMetadataText({super.key, required this.metadataText});

  final String metadataText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        minWidth: double.infinity,
      ),
      child: Scrollbar(
        radius: const Radius.circular(16.0),
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: AutoSizeText(
            metadataText,
            style: Theme.of(context).paymentItemSubtitleTextStyle.copyWith(color: Colors.white70),
            minFontSize: MinFontSize(context).minFontSize,
          ),
        ),
      ),
    );
  }
}

class LNURLMetadataImage extends StatelessWidget {
  final String? base64String;

  const LNURLMetadataImage({super.key, this.base64String});

  @override
  Widget build(BuildContext context) {
    if (base64String != null) {
      final bytes = base64Decode(base64String!);
      if (bytes.isNotEmpty) {
        const imageSize = 128.0;
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: imageSize,
            maxHeight: imageSize,
          ),
          child: Image.memory(
            bytes,
            width: imageSize,
            fit: BoxFit.fitWidth,
          ),
        );
      }
    }
    return Container();
  }
}
