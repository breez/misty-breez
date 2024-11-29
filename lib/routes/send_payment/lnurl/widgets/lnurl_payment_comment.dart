import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/theme/src/theme.dart';

class LnUrlPaymentComment extends StatelessWidget {
  final bool enabled;
  final int maxCommentLength;
  final TextEditingController descriptionController;
  final FocusNode descriptionFocusNode;

  const LnUrlPaymentComment({
    required this.enabled,
    required this.descriptionController,
    required this.descriptionFocusNode,
    required this.maxCommentLength,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextFormField(
        enabled: enabled,
        readOnly: !enabled,
        controller: descriptionController,
        focusNode: descriptionFocusNode,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.done,
        maxLines: null,
        maxLength: maxCommentLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        decoration: InputDecoration(
          prefixIconConstraints: BoxConstraints.tight(
            const Size(16, 56),
          ),
          prefixIcon: const SizedBox.shrink(),
          contentPadding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
          border: const OutlineInputBorder(),
          labelText: texts.lnurl_payment_page_comment_label,
          counterStyle: descriptionFocusNode.hasFocus ? focusedCounterTextStyle : counterTextStyle,
        ),
        style: FieldTextStyle.textStyle,
      ),
    );
  }
}
