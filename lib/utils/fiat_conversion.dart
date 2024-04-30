import 'dart:math';

import 'package:breez_sdk/sdk.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/utils/currency_formatter.dart';

class FiatConversion {
  FiatCurrency currencyData;
  double exchangeRate;

  FiatConversion(this.currencyData, this.exchangeRate);

  String get logoPath {
    switch (currencyData.info.symbol ?? "") {
      case "€":
        return "src/icon/btc_eur.png";
      case "£":
        return "src/icon/btc_gbp.png";
      case "¥":
        return "src/icon/btc_yen.png";
      case "\$":
        return "src/icon/btc_usd.png";
      default:
        return "src/icon/btc_convert.png";
    }
  }

  int fiatToSat(double fiatAmount) {
    return (fiatAmount / exchangeRate * 100000000).round();
  }

  RegExp get whitelistedPattern => currencyData.info.fractionSize == 0
      ? RegExp(r'\d+')
      : RegExp("^\\d+[.,]?\\d{0,${currencyData.info.fractionSize}}");

  double satToFiat(int satoshies) {
    return satoshies.toDouble() / 100000000 * exchangeRate;
  }

  String format(int amount) {
    double fiatValue = satToFiat(amount);
    return formatFiat(fiatValue);
  }

  String formatFiat(
    double fiatAmount, {
    bool removeTrailingZeros = false,
  }) {
    final locale = getSystemLocale();
    final localeOverride = _localeOverride(locale.toLanguageTag(), locale.languageCode);

    int fractionSize = currencyData.info.fractionSize;
    double minimumAmount = 1 / (pow(10, fractionSize));

    String formattedAmount = "";
    String spacing = " " * (localeOverride?.spacing ?? currencyData.info.spacing ?? 0);
    final symbolPosition = localeOverride?.symbol.position ?? currencyData.info.symbol?.position;
    final symbolGrapheme = localeOverride?.symbol.grapheme ?? currencyData.info.symbol?.grapheme;
    String symbolText =
        (symbolPosition == 1) ? spacing + (symbolGrapheme ?? "") : (symbolGrapheme ?? "") + spacing;
    // if conversion result is less than the minimum it doesn't make sense to display it
    if (fiatAmount < minimumAmount) {
      formattedAmount = minimumAmount.toStringAsFixed(fractionSize);
      symbolText = '< $symbolText';
    } else {
      final formatter = CurrencyFormatter().formatter;
      formatter.minimumFractionDigits = fractionSize;
      formatter.maximumFractionDigits = fractionSize;
      formattedAmount = formatter.format(fiatAmount);
    }
    formattedAmount = (symbolPosition == 1) ? formattedAmount + symbolText : symbolText + formattedAmount;
    if (removeTrailingZeros) {
      RegExp removeTrailingZeros = RegExp(r"([.]0*)(?!.*\d)");
      formattedAmount = formattedAmount.replaceAll(removeTrailingZeros, "");
    }
    return formattedAmount;
  }

  double get satConversionRate => 1 / exchangeRate * 100000000;

  LocaleOverrides? _localeOverride(String languageTag, String languageCode) {
    final localeOverrides = currencyData.info.localeOverrides;
    if (localeOverrides == null || localeOverrides.isEmpty) return null;
    if (localeOverrides.any((e) => e.locale == languageTag)) {
      return localeOverrides.firstWhere((e) => e.locale == languageTag);
    }
    if (localeOverrides.any((e) => e.locale == languageCode)) {
      return localeOverrides.firstWhere((e) => e.locale == languageCode);
    }
    return null;
  }
}
