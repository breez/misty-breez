import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';

class PaymentsFilterDropdown extends StatelessWidget {
  final String filter;
  final ValueChanged<Object?> onFilterChanged;

  const PaymentsFilterDropdown(this.filter, this.onFilterChanged, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final Color foregroundColor = themeData.isLightTheme ? Colors.black : themeData.colorScheme.onSecondary;

    return Theme(
      data: themeData.copyWith(canvasColor: themeData.customData.paymentListBgColor),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: filter,
            iconEnabledColor: foregroundColor,
            style: themeData.textTheme.titleSmall?.copyWith(color: foregroundColor),
            items:
                <String>[
                  texts.payments_filter_option_all,
                  texts.payments_filter_option_sent,
                  texts.payments_filter_option_received,
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Material(
                      child: Text(
                        value,
                        style: themeData.textTheme.titleSmall?.copyWith(color: foregroundColor),
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (String? item) => onFilterChanged(item),
          ),
        ),
      ),
    );
  }
}
