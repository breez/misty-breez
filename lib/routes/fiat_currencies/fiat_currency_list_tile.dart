import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;

const double itemHeight = 72.0;

class FiatCurrencyListTile extends StatelessWidget {
  final int index;
  final CurrencyState currencyState;
  final ScrollController scrollController;
  final Function(List<String> prefCurrencies) onChanged;

  const FiatCurrencyListTile({
    super.key,
    required this.index,
    required this.currencyState,
    required this.scrollController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    final currencyData = currencyState.fiatCurrenciesData[index];
    final prefCurrencies = currencyState.preferredCurrencies.toList();

    String subtitle = currencyData.info.name;
    final localizedName = currencyData.info.localizedName;
    if (localizedName.isNotEmpty) {
      for (var localizedName in localizedName) {
        if (localizedName.locale == texts.locale) {
          subtitle = localizedName.name;
        }
      }
    }

    return CheckboxListTile(
      key: Key("tile-index-$index"),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.white,
      checkColor: themeData.canvasColor,
      value: prefCurrencies.contains(currencyData.id),
      onChanged: (bool? checked) {
        if (checked == true) {
          prefCurrencies.add(currencyData.id);
          // center item in viewport
          if (scrollController.offset >= (itemHeight * (prefCurrencies.length - 1))) {
            scrollController.animateTo(
              ((2 * prefCurrencies.length - 1) * itemHeight - scrollController.position.viewportDimension) /
                  2,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 400),
            );
          }
        } else if (currencyState.preferredCurrencies.length != 1) {
          prefCurrencies.remove(currencyData.id);
        }
        onChanged(prefCurrencies);
      },
      subtitle: Text(
        subtitle,
        style: theme.fiatConversionDescriptionStyle,
      ),
      title: RichText(
        text: TextSpan(
          text: currencyData.id,
          style: theme.fiatConversionTitleStyle,
          children: [
            TextSpan(
              text: " (${currencyData.info.symbol?.grapheme ?? ""})",
              style: theme.fiatConversionDescriptionStyle,
            ),
          ],
        ),
      ),
    );
  }
}
