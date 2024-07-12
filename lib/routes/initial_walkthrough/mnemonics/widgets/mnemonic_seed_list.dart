import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'mnemonic_item.dart';

class MnemonicSeedList extends StatelessWidget {
  final List<String> mnemonicsList;

  const MnemonicSeedList({super.key, required this.mnemonicsList});

  get autoSizeGroup => AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: List<Widget>.generate(
            6,
            (index) => MnemonicItem(
              mnemonic: mnemonicsList[2 * index],
              index: 2 * index,
              autoSizeGroup: autoSizeGroup,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: List<Widget>.generate(
            6,
            (index) => MnemonicItem(
              mnemonic: mnemonicsList[1 + 2 * index],
              index: 1 + 2 * index,
              autoSizeGroup: autoSizeGroup,
            ),
          ),
        ),
      ],
    );
  }
}
