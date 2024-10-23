import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/theme/src/theme.dart';

class LnUrlPaymentComment extends StatelessWidget {
  final int maxCommentLength;
  final TextEditingController descriptionController;

  const LnUrlPaymentComment({
    super.key,
    required this.descriptionController,
    required this.maxCommentLength,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return TextFormField(
      controller: descriptionController,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.done,
      maxLines: null,
      maxLength: maxCommentLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        labelText: "${texts.lnurl_payment_page_comment}:",
        labelStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(color: Colors.white),
      ),
      style: themeData.paymentItemSubtitleTextStyle.copyWith(color: Colors.white70),
    );
  }
}
