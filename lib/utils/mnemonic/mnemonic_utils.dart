import 'package:flutter/material.dart';
import 'package:misty_breez/utils/constants/app_constants.dart';

class MnemonicUtils {
  static const int wordCount = 12;

  static bool tryPopulateTextFieldsFromText(
    String? text,
    List<TextEditingController> controllers,
  ) {
    if (text == null || !text.contains(' ')) {
      return false;
    }

    final List<String> words = text.trim().toLowerCase().split(RegExp(r'\s+'));

    if (words.length != wordCount || !words.every(wordlist.contains)) {
      return false;
    }

    for (int i = 0; i < wordCount; i++) {
      controllers[i].text = words[i];
    }

    FocusManager.instance.primaryFocus?.unfocus();
    return true;
  }
}
