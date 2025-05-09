import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';

class FiatInputField extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FiatConversion? fiatConversion;
  final String? Function(int amount) validatorFn;

  const FiatInputField({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.fiatConversion,
    required this.validatorFn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (fiatConversion == null) {
      return const SizedBox.shrink();
    }

    final ThemeData themeData = Theme.of(context);
    final Color errorBorderColor = themeData.isLightTheme ? Colors.red : themeData.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            labelText: 'Amount in ${fiatConversion!.currencyData.id}',
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: errorBorderColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: errorBorderColor),
            ),
            errorMaxLines: 2,
            errorStyle: themeData.primaryTextTheme.bodySmall!.copyWith(
              color: errorBorderColor,
            ),
            prefix: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text(
                fiatConversion!.currencyData.info.symbol?.grapheme ?? '',
              ),
            ),
            border: const OutlineInputBorder(),
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(
              fiatConversion!.whitelistedPattern,
            ),
            TextInputFormatter.withFunction(
              (_, TextEditingValue newValue) => newValue.copyWith(
                text: newValue.text.replaceAll(',', '.'),
              ),
            ),
          ],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          onEditingComplete: () => focusNode.unfocus(),
          validator: (_) {
            final double inputAmount = double.tryParse(controller.text) ?? 0;
            final int amountSat = fiatConversion!.fiatToSat(inputAmount);
            return validatorFn(amountSat);
          },
        ),
      ),
    );
  }
}
