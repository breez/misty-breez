import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;

class EnterMnemonicsPageArguments {
  final List<String> initialWords;
  final String errorMessage;

  EnterMnemonicsPageArguments({required this.initialWords, this.errorMessage = ''});
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

  List<TextEditingController> textEditingControllers = List<TextEditingController>.generate(
    12,
    (_) => TextEditingController(),
  );

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
          actions: <Widget>[PasteBackupPhraseButton(textEditingControllers: textEditingControllers)],
          title: Text(texts.enter_backup_phrase(_currentPage.toString(), _lastPage.toString())),
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
}
