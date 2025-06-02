import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

export 'currency_converter_bottom_sheet.dart';
export 'input_formatter/sat_amount_form_field_formatter.dart';
export 'widgets/widgets.dart';

class AmountFormField extends TextFormField {
  final FiatConversion? fiatConversion;
  final BitcoinCurrency bitcoinCurrency;
  final String? Function(int amount) validatorFn;
  final BreezTranslations texts;

  AmountFormField({
    required this.bitcoinCurrency,
    required this.validatorFn,
    required this.texts,
    required BuildContext context,
    super.key,
    this.fiatConversion,
    Color? iconColor,
    Function(String amount)? returnFN,
    super.controller,
    String? initialValue,
    super.focusNode,
    InputDecoration decoration = const InputDecoration(),
    super.style,
    TextAlign textAlign = TextAlign.start,
    int maxLines = 1,
    int? maxLength,
    super.onFieldSubmitted,
    super.onSaved,
    super.enabled,
    super.enableInteractiveSelection,
    super.onChanged,
    bool? readOnly,
    bool? autofocus,
    int? errorMaxLines,
    TextStyle? labelStyle,
    TextStyle? floatingLabelStyle,
    TextStyle? errorStyle,
  }) : super(
         keyboardType: TextInputType.numberWithOptions(decimal: bitcoinCurrency != BitcoinCurrency.sat),
         autofocus: autofocus ?? false,
         decoration: InputDecoration(
           border: const OutlineInputBorder(),
           prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
           prefixIcon: const SizedBox.shrink(),
           label: Text(texts.amount_form_denomination(bitcoinCurrency.displayName), style: labelStyle),
           contentPadding: EdgeInsets.zero,
           floatingLabelStyle: floatingLabelStyle,
           errorStyle: errorStyle,
           errorMaxLines: errorMaxLines ?? 3,
           suffixIcon: (readOnly ?? false)
               ? null
               : IconButton(
                   icon: Image.asset(
                     (fiatConversion?.currencyData != null)
                         ? fiatConversion!.logoPath
                         : 'assets/icons/btc_convert.png',
                     color: iconColor ?? BreezColors.white[500],
                     height: 24,
                   ),
                   padding: const EdgeInsets.only(bottom: 12.0, right: 12.0),
                   alignment: Alignment.bottomRight,
                   onPressed: () => showModalBottomSheet(
                     context: context,
                     backgroundColor: Theme.of(context).customData.paymentListBgColor,
                     shape: const RoundedRectangleBorder(
                       borderRadius: BorderRadius.all(Radius.circular(12.0)),
                     ),
                     isScrollControlled: true,
                     builder: (BuildContext context) => CurrencyConverterBottomSheet(
                       onConvert:
                           returnFN ??
                           (String value) {
                             return controller!.text = bitcoinCurrency.format(
                               bitcoinCurrency.parse(value),
                               includeDisplayName: false,
                             );
                           },
                       validatorFn: validatorFn,
                     ),
                   ),
                 ),
         ),
         inputFormatters: bitcoinCurrency != BitcoinCurrency.sat
             ? <TextInputFormatter>[
                 FilteringTextInputFormatter.allow(bitcoinCurrency.whitelistedPattern),
                 TextInputFormatter.withFunction(
                   (_, TextEditingValue newValue) =>
                       newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
                 ),
               ]
             : <TextInputFormatter>[SatAmountFormFieldFormatter()],
         readOnly: readOnly ?? false,
       );

  @override
  FormFieldValidator<String?> get validator {
    return (String? value) {
      if (value!.isEmpty) {
        return texts.amount_form_insert_hint(bitcoinCurrency.displayName);
      }
      try {
        final int intAmount = bitcoinCurrency.parse(value);
        if (intAmount <= 0) {
          return texts.amount_form_error_invalid_amount;
        }
        return validatorFn(intAmount);
      } catch (err) {
        return texts.amount_form_error_invalid_amount;
      }
    };
  }
}
