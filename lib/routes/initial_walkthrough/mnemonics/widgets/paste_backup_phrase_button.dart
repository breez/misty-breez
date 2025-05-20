import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/utils/utils.dart';
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
        Icons.paste,
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
      final bool success = MnemonicUtils.tryPopulateTextFieldsFromText(
        clipboardData?.text,
        widget.textEditingControllers,
      );
      if (!success) {
        throw 'Clipboard has invalid backup phrase.';
      }
    } catch (e) {
      if (mounted) {
        showFlushbar(context, message: e.toString());
      }
    }
  }
}
