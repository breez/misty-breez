import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';

class VerifyForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<String> mnemonicsList;
  final List<int> randomlySelectedIndexes;
  final VoidCallback onError;
  final Widget errorText;

  const VerifyForm({
    required this.formKey,
    required this.mnemonicsList,
    required this.randomlySelectedIndexes,
    required this.onError,
    required this.errorText,
    super.key,
  });

  @override
  VerifyFormPageState createState() => VerifyFormPageState();
}

class VerifyFormPageState extends State<VerifyForm> {
  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return Form(
      key: widget.formKey,
      onChanged: () => widget.formKey.currentState?.save(),
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(
            widget.randomlySelectedIndexes.length,
            (int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: texts.backup_phrase_generation_type_step(
                      widget.randomlySelectedIndexes[index] + 1,
                    ),
                  ),
                  style: FieldTextStyle.textStyle,
                  validator: (String? text) {
                    if (text!.isEmpty ||
                        text.toLowerCase().trim() !=
                            widget.mnemonicsList[widget.randomlySelectedIndexes[index]]) {
                      widget.onError();
                    }
                    return null;
                  },
                  onEditingComplete: () =>
                      (index == 2) ? FocusScope.of(context).unfocus() : FocusScope.of(context).nextFocus(),
                ),
              );
            },
          )..add(widget.errorText),
        ),
      ),
    );
  }
}
