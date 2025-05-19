import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/utils/constants/app_constants.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PasteBackupPhraseButton extends StatefulWidget {
  final List<TextEditingController> textEditingControllers;

  const PasteBackupPhraseButton({
    required this.textEditingControllers,
    super.key,
  });

  @override
  State<PasteBackupPhraseButton> createState() => _PasteBackupPhraseButtonState();
}

class _PasteBackupPhraseButtonState extends State<PasteBackupPhraseButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.content_paste_outlined,
        color: Colors.white,
        size: 20,
      ),
      tooltip: 'Paste Backup Phrase',
      onPressed: _pasteBackupPhrase,
    );
  }

  void _pasteBackupPhrase() async {
    try {
      final ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final String? clipboardText = clipboardData?.text?.trim();

      if (clipboardText == null) {
        throw 'Clipboard is empty.';
      }

      final List<String> words = _extractWords(clipboardText);

      if (_isValidMnemonic(words)) {
        _populateTextFields(words);
      } else {
        throw 'Clipboard has invalid backup phrase.';
      }
    } catch (e) {
      if (mounted) {
        showFlushbar(context, message: e.toString());
      }
    }
  }

  List<String> _extractWords(String text) {
    return text.split(RegExp(r'\s+')).map((String word) => word.toLowerCase().trim()).toList();
  }

  bool _isValidMnemonic(List<String> words) {
    return words.length == 12 && words.every((String word) => wordlist.contains(word));
  }

  void _populateTextFields(List<String> words) {
    for (int i = 0; i < words.length; i++) {
      widget.textEditingControllers[i].text = words[i];
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
