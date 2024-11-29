import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';

class FiatCurrencyChips extends StatelessWidget {
  final String? selectedCurrency;
  final ValueChanged<String> onCurrencySelected;

  const FiatCurrencyChips({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: currencyState.preferredCurrencies.map(
            (String currencyId) {
              final FiatCurrency fiatCurrency = currencyState.fiatCurrenciesData.firstWhere(
                (FiatCurrency c) => c.id == currencyId,
              );

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(fiatCurrency.id),
                  selected: selectedCurrency == fiatCurrency.id,
                  onSelected: (bool selected) {
                    if (selected) {
                      onCurrencySelected(fiatCurrency.id);
                    }
                  },
                  selectedColor: themeData.chipTheme.backgroundColor,
                  backgroundColor:
                      themeData.isLightTheme ? themeData.primaryColorDark : Colors.white.withAlpha(0x1f),
                  labelStyle: TextStyle(
                    color: selectedCurrency == fiatCurrency.id
                        ? Colors.white
                        : themeData.textTheme.bodyMedium?.color,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
