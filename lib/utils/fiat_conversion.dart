import 'dart:math';
import 'dart:ui';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:intl/intl.dart';
import 'package:l_breez/utils/currency_formatter.dart';

class FiatConversion {
  FiatCurrency currencyData;
  double exchangeRate;

  FiatConversion(this.currencyData, this.exchangeRate);

  String get logoPath {
    switch (currencyData.info.symbol ?? '') {
      case '€':
        return 'assets/icons/btc_eur.png';
      case '£':
        return 'assets/icons/btc_gbp.png';
      case '¥':
        return 'assets/icons/btc_yen.png';
      case '\$':
        return 'assets/icons/btc_usd.png';
      default:
        return 'assets/icons/btc_convert.png';
    }
  }

  int fiatToSat(double fiatAmount) {
    return (fiatAmount / exchangeRate * 100000000).round();
  }

  RegExp get whitelistedPattern => currencyData.info.fractionSize == 0
      ? RegExp(r'\d+')
      : RegExp('^\\d+[.,]?\\d{0,${currencyData.info.fractionSize}}');

  double satToFiat(int satoshies) {
    return satoshies.toDouble() / 100000000 * exchangeRate;
  }

  String format(
    int amount, {
    bool includeDisplayName = false,
    bool addCurrencySymbol = true,
    bool removeTrailingZeros = false,
  }) {
    final double fiatValue = satToFiat(amount);
    return formatFiat(
      fiatValue,
      includeDisplayName: includeDisplayName,
      addCurrencySymbol: addCurrencySymbol,
      removeTrailingZeros: removeTrailingZeros,
    );
  }

  String formatFiat(
    double fiatAmount, {
    bool includeDisplayName = false,
    bool addCurrencySymbol = true,
    bool removeTrailingZeros = false,
  }) {
    final Locale locale = getSystemLocale();
    final LocaleOverrides? localeOverride = _localeOverride(locale.toLanguageTag(), locale.languageCode);

    final int fractionSize = currencyData.info.fractionSize;
    final double minimumAmount = 1 / (pow(10, fractionSize));

    String formattedAmount = '';
    final String spacing = ' ' * (localeOverride?.spacing ?? currencyData.info.spacing ?? 0);
    final int? symbolPosition = localeOverride?.symbol.position ?? currencyData.info.symbol?.position;
    final String? symbolGrapheme = localeOverride?.symbol.grapheme ?? currencyData.info.symbol?.grapheme;
    String symbolText =
        (symbolPosition == 1) ? spacing + (symbolGrapheme ?? '') : (symbolGrapheme ?? '') + spacing;
    // if conversion result is less than the minimum it doesn't make sense to display it
    if (fiatAmount < minimumAmount) {
      formattedAmount = minimumAmount.toStringAsFixed(fractionSize);
      symbolText = '< $symbolText';
    } else {
      final NumberFormat formatter = CurrencyFormatter().formatter;
      formatter.minimumFractionDigits = fractionSize;
      formatter.maximumFractionDigits = fractionSize;
      formattedAmount = formatter.format(fiatAmount);
    }
    if (addCurrencySymbol) {
      formattedAmount = (symbolPosition == 1) ? formattedAmount + symbolText : symbolText + formattedAmount;
    } else if (includeDisplayName) {
      formattedAmount += ' ${currencyData.id}';
    }
    if (removeTrailingZeros) {
      final RegExp removeTrailingZeros = RegExp(r'([.]0*)(?!.*\d)');
      formattedAmount = formattedAmount.replaceAll(removeTrailingZeros, '');
    }
    return formattedAmount;
  }

  double get satConversionRate => 1 / exchangeRate * 100000000;

  LocaleOverrides? _localeOverride(String languageTag, String languageCode) {
    final List<LocaleOverrides> localeOverrides = currencyData.info.localeOverrides;
    if (localeOverrides.isEmpty) {
      return null;
    }
    if (localeOverrides.any((LocaleOverrides e) => e.locale == languageTag)) {
      return localeOverrides.firstWhere((LocaleOverrides e) => e.locale == languageTag);
    }
    if (localeOverrides.any((LocaleOverrides e) => e.locale == languageCode)) {
      return localeOverrides.firstWhere((LocaleOverrides e) => e.locale == languageCode);
    }
    return null;
  }
}
