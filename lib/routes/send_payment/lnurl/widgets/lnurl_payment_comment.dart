import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/theme/src/theme.dart';

class LnUrlPaymentComment extends StatelessWidget {
  final bool enabled;
  final int maxCommentLength;
  final TextEditingController descriptionController;

  const LnUrlPaymentComment({
    required this.enabled,
    required this.descriptionController,
    required this.maxCommentLength,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return TextFormField(
      enabled: enabled,
      readOnly: !enabled,
      controller: descriptionController,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.done,
      maxLines: null,
      maxLength: maxCommentLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        labelText: texts.lnurl_payment_page_comment_label,
        labelStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(color: Colors.white),
      ),
      style: themeData.paymentItemSubtitleTextStyle.copyWith(color: Colors.white70),
    );
  }
}
