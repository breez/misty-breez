import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/fiat_conversion.dart';
import 'package:l_breez/widgets/widgets.dart';

export 'currency_converter_dialog.dart';
export 'sat_amount_form_field_formatter.dart';

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
  }) : super(
          keyboardType: TextInputType.numberWithOptions(
            decimal: bitcoinCurrency != BitcoinCurrency.sat,
          ),
          autofocus: autofocus ?? false,
          decoration: InputDecoration(
            labelText: texts.amount_form_denomination(
              bitcoinCurrency.displayName,
            ),
            errorMaxLines: errorMaxLines,
            suffixIcon: (readOnly ?? false)
                ? null
                : IconButton(
                    icon: Image.asset(
                      (fiatConversion?.currencyData != null)
                          ? fiatConversion!.logoPath
                          : 'assets/icons/btc_convert.png',
                      color: iconColor ?? BreezColors.white[500],
                    ),
                    padding: const EdgeInsets.only(top: 21.0),
                    alignment: Alignment.bottomRight,
                    onPressed: () => showDialog(
                      useRootNavigator: false,
                      context: context,
                      builder: (_) => CurrencyConverterDialog(
                        context.read<CurrencyCubit>(),
                        returnFN ??
                            (String value) => controller!.text = bitcoinCurrency.format(
                                  bitcoinCurrency.parse(value),
                                  includeDisplayName: false,
                                ),
                        validatorFn,
                      ),
                    ),
                  ),
          ),
          inputFormatters: bitcoinCurrency != BitcoinCurrency.sat
              ? <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(bitcoinCurrency.whitelistedPattern),
                  TextInputFormatter.withFunction(
                    (_, TextEditingValue newValue) => newValue.copyWith(
                      text: newValue.text.replaceAll(',', '.'),
                    ),
                  ),
                ]
              : <TextInputFormatter>[SatAmountFormFieldFormatter()],
          readOnly: readOnly ?? false,
        );

  @override
  FormFieldValidator<String?> get validator {
    return (String? value) {
      if (value!.isEmpty) {
        return texts.amount_form_insert_hint(
          bitcoinCurrency.displayName,
        );
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
