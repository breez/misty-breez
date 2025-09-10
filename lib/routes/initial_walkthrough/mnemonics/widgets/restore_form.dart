import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';

class RestoreForm extends StatefulWidget {
  final GlobalKey formKey;
  final int currentPage;
  final int lastPage;
  final List<TextEditingController> textEditingControllers;
  final AutovalidateMode autoValidateMode;

  const RestoreForm({
    required this.formKey,
    required this.currentPage,
    required this.lastPage,
    required this.textEditingControllers,
    required this.autoValidateMode,
    super.key,
  });

  @override
  RestoreFormState createState() => RestoreFormState();
}

class RestoreFormState extends State<RestoreForm> {
  List<FocusNode> focusNodes = List<FocusNode>.generate(12, (_) => FocusNode());

  late AutovalidateMode _autoValidateMode;

  @override
  void initState() {
    super.initState();
    _autoValidateMode = AutovalidateMode.disabled;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(6, (int index) {
            final int itemIndex = index + (6 * (widget.currentPage - 1));
            return TypeAheadFormField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                autocorrect: false,
                controller: widget.textEditingControllers[itemIndex],
                textInputAction: TextInputAction.next,
                onSubmitted: (String text) async {
                  final List<String> suggestions = await _getSuggestions(text);
                  widget.textEditingControllers[itemIndex].text = suggestions.length == 1
                      ? suggestions.first
                      : text;
                  if (itemIndex + 1 < focusNodes.length) {
                    focusNodes[itemIndex + 1].requestFocus();
                  }
                },
                focusNode: focusNodes[itemIndex],
                decoration: InputDecoration(labelText: '${itemIndex + 1}'),
                style: FieldTextStyle.textStyle,
                onChanged: _processPotentialBackupPhrase,
              ),
              autovalidateMode: _autoValidateMode,
              validator: (String? text) => _onValidate(context, text!),
              suggestionsCallback: _getSuggestions,
              hideOnEmpty: true,
              hideOnLoading: true,
              autoFlipDirection: true,
              suggestionsBoxDecoration: const SuggestionsBoxDecoration(
                color: Colors.white,
                constraints: BoxConstraints(minWidth: 180, maxWidth: 180, maxHeight: 180),
              ),
              itemBuilder: <BuildContext_, String_>(BuildContext context, dynamic suggestion) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(width: 0.5, color: Color.fromRGBO(5, 93, 235, 1.0))),
                  ),
                  child: ListTile(
                    title: Text(suggestion, overflow: TextOverflow.ellipsis, style: autoCompleteStyle),
                  ),
                );
              },
              onSuggestionSelected: <String_>(dynamic suggestion) {
                widget.textEditingControllers[itemIndex].text = suggestion;
                if (itemIndex + 1 < focusNodes.length) {
                  focusNodes[itemIndex + 1].requestFocus();
                }
              },
            );
          }),
        ),
      ),
    );
  }

  String? _onValidate(BuildContext context, String text) {
    final BreezTranslations texts = context.texts();
    if (text.isEmpty) {
      return texts.enter_backup_phrase_missing_word;
    }
    if (!wordlist.contains(text.toLowerCase().trim())) {
      return texts.enter_backup_phrase_invalid_word;
    }
    return null;
  }

  FutureOr<List<String>> _getSuggestions(String pattern) {
    if (pattern.toString().isEmpty) {
      return List<String>.empty();
    } else {
      final List<String> suggestionList = wordlist.where((String item) => item.startsWith(pattern)).toList();
      return suggestionList.isNotEmpty ? suggestionList : List<String>.empty();
    }
  }

  void _processPotentialBackupPhrase(String? backupPhrase) {
    MnemonicUtils.tryPopulateTextFieldsFromText(backupPhrase, widget.textEditingControllers);
  }
}
