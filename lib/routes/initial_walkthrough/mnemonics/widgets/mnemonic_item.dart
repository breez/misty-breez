import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/min_font_size.dart';

class MnemonicItem extends StatelessWidget {
  final String mnemonic;
  final int index;
  final AutoSizeGroup? autoSizeGroup;

  const MnemonicItem({
    super.key,
    required this.mnemonic,
    required this.index,
    this.autoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Container(
      height: 48,
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: const BorderRadius.all(
          Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          Text(
            texts.backup_phrase_generation_index(index + 1),
            style: mnemonicSeedTextStyle,
          ),
          Expanded(
            child: AutoSizeText(
              mnemonic,
              style: mnemonicSeedTextStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              minFontSize: MinFontSize(context).minFontSize,
              stepGranularity: 0.1,
              group: autoSizeGroup,
            ),
          ),
        ],
      ),
    );
  }
}
