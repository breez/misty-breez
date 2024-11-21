import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/min_font_size.dart';

class LNURLMetadataText extends StatefulWidget {
  const LNURLMetadataText({required this.metadataText, super.key});

  final String metadataText;

  @override
  State<LNURLMetadataText> createState() => _LNURLMetadataTextState();
}

class _LNURLMetadataTextState extends State<LNURLMetadataText> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        minWidth: double.infinity,
      ),
      child: Scrollbar(
        controller: _scrollController,
        radius: const Radius.circular(16.0),
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: AutoSizeText(
            widget.metadataText,
            style: Theme.of(context).paymentItemSubtitleTextStyle.copyWith(color: Colors.white70),
            minFontSize: MinFontSize(context).minFontSize,
          ),
        ),
      ),
    );
  }
}
