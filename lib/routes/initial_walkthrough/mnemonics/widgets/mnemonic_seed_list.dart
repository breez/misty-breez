import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';

class MnemonicSeedList extends StatelessWidget {
  final List<String> mnemonicsList;

  const MnemonicSeedList({required this.mnemonicsList, super.key});

  AutoSizeGroup get autoSizeGroup => AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List<Widget>.generate(
            6,
            (int index) => MnemonicItem(
              mnemonic: mnemonicsList[2 * index],
              index: 2 * index,
              autoSizeGroup: autoSizeGroup,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List<Widget>.generate(
            6,
            (int index) => MnemonicItem(
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
