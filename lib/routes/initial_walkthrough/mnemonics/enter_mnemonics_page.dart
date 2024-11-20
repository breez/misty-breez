import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/widgets/restore_form_page.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;

class EnterMnemonicsPage extends StatefulWidget {
  final List<String> initialWords;

  static const String routeName = '/enter_mnemonics';

  const EnterMnemonicsPage({required this.initialWords, super.key});

  @override
  EnterMnemonicsPageState createState() => EnterMnemonicsPageState();
}

class EnterMnemonicsPageState extends State<EnterMnemonicsPage> {
  late int _currentPage = 1;
  final int _lastPage = 2;

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final MediaQueryData query = MediaQuery.of(context);

    return PopScope(
      canPop: _currentPage == 1,
      onPopInvoked: (bool didPop) async {
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
              initialWords: widget.initialWords,
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
