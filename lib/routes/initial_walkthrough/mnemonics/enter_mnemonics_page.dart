import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/constants/wordlist.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class EnterMnemonicsPageArguments {
  final List<String> initialWords;
  final String errorMessage;

  EnterMnemonicsPageArguments({
    required this.initialWords,
    this.errorMessage = '',
  });
}

class EnterMnemonicsPage extends StatefulWidget {
  final EnterMnemonicsPageArguments arguments;

  static const String routeName = '/enter_mnemonics';

  const EnterMnemonicsPage({required this.arguments, super.key});

  @override
  EnterMnemonicsPageState createState() => EnterMnemonicsPageState();
}

class EnterMnemonicsPageState extends State<EnterMnemonicsPage> {
  int _currentPage = 1;
  final int _lastPage = 2;

  List<TextEditingController> textEditingControllers =
      List<TextEditingController>.generate(12, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _currentPage = widget.arguments.errorMessage.isNotEmpty ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final MediaQueryData query = MediaQuery.of(context);

    return PopScope(
      canPop: _currentPage == 1,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (_currentPage > 1) {
          FocusScope.of(context).requestFocus(FocusNode());
          setState(() {
            _currentPage--;
          });
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: back_button.BackButton(
            onPressed: () {
              if (_currentPage == 1) {
                Navigator.pop(context);
              } else if (_currentPage > 1) {
                FocusScope.of(context).requestFocus(FocusNode());
                setState(() {
                  _currentPage--;
                });
              }
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.content_paste_outlined,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Paste Backup Phrase',
              onPressed: _pasteBackupPhrase,
            ),
          ],
          title: Text(
            texts.enter_backup_phrase(
              _currentPage.toString(),
              _lastPage.toString(),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: query.size.height - kToolbarHeight - query.padding.top,
            child: RestoreFormPage(
              currentPage: _currentPage,
              lastPage: _lastPage,
              initialWords: widget.arguments.initialWords,
              lastErrorMessage: widget.arguments.errorMessage,
              textEditingControllers: textEditingControllers,
              changePage: () {
                setState(() {
                  _currentPage++;
                });
              },
            ),
          ),
        ),
      ),
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
      textEditingControllers[i].text = words[i];
    }
  }
}
