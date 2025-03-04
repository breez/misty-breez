import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/widgets/widgets.dart';

class LnUrlPaymentComment extends StatelessWidget {
  final bool isConfirmation;
  final bool enabled;
  final int maxCommentLength;
  final TextEditingController descriptionController;
  final FocusNode descriptionFocusNode;

  const LnUrlPaymentComment({
    required this.isConfirmation,
    required this.enabled,
    required this.descriptionController,
    required this.descriptionFocusNode,
    required this.maxCommentLength,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    if (isConfirmation) {
      if (descriptionController.text.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AutoSizeText(
              // TODO(erdemyerebasmaz): Add message to Breez-Translations instead of reusing another value
              texts.payment_details_dialog_share_comment,
              style: themeData.primaryTextTheme.headlineMedium?.copyWith(
                fontSize: 18.0,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
              maxLines: 1,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: WarningBox(
                boxPadding: EdgeInsets.zero,
                backgroundColor: themeData.primaryColorLight.withValues(alpha: .1),
                borderColor: themeData.primaryColorLight.withValues(alpha: .7),
                child: LNURLMetadataText(metadataText: descriptionController.text),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
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
