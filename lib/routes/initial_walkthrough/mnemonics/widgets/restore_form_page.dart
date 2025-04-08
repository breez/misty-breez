import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class RestoreFormPage extends StatefulWidget {
  final int currentPage;
  final int lastPage;
  final VoidCallback changePage;
  final List<String> initialWords;

  const RestoreFormPage({
    required this.currentPage,
    required this.lastPage,
    required this.changePage,
    super.key,
    this.initialWords = const <String>[],
  });

  @override
  RestoreFormPageState createState() => RestoreFormPageState();
}

class RestoreFormPageState extends State<RestoreFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<TextEditingController> textEditingControllers =
      List<TextEditingController>.generate(12, (_) => TextEditingController());

  late AutovalidateMode _autoValidateMode;
  late bool _hasError;

  @override
  void initState() {
    super.initState();
    _autoValidateMode = AutovalidateMode.disabled;
    _hasError = false;
    for (int i = 0; i < textEditingControllers.length && i < widget.initialWords.length; i++) {
      textEditingControllers[i].text = widget.initialWords[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final BreezTranslations texts = context.texts();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        RestoreForm(
          formKey: _formKey,
          currentPage: widget.currentPage,
          lastPage: widget.lastPage,
          textEditingControllers: textEditingControllers,
          autoValidateMode: _autoValidateMode,
        ),
        if (_hasError) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Text(
              texts.enter_backup_phrase_error,
              style: themeData.textTheme.headlineMedium?.copyWith(
                fontSize: 12,
              ),
            ),
          ),
        ],
        SingleButtonBottomBar(
          text: widget.currentPage + 1 == (widget.lastPage + 1)
              ? texts.enter_backup_phrase_action_restore
              : texts.enter_backup_phrase_action_next,
          onPressed: () {
            setState(() {
              _hasError = false;
              if (_formKey.currentState!.validate() && !_hasError) {
                _autoValidateMode = AutovalidateMode.disabled;
                if (widget.currentPage + 1 == (widget.lastPage + 1)) {
                  _validateMnemonics();
                } else {
                  widget.changePage();
                }
              } else {
                _autoValidateMode = AutovalidateMode.always;
              }
            });
          },
        ),
      ],
    );
  }

  Future<void> _validateMnemonics() async {
    final BreezTranslations texts = context.texts();
    final String mnemonic = textEditingControllers
        .map((TextEditingController controller) => controller.text.toLowerCase().trim())
        .toList()
        .join(' ');
    try {
      Navigator.pop(context, mnemonic);
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      throw Exception(ExceptionHandler.extractMessage(e, texts));
    }
  }
}
