import 'dart:math';
import 'dart:ui';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:intl/intl.dart';
import 'package:l_breez/utils/utils.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('FiatConversion');

/// Handles conversion between Bitcoin and fiat currencies
class FiatConversion {
  /// The fiat currency data
  final FiatCurrency currencyData;

  /// The exchange rate (Bitcoin to fiat)
  final double exchangeRate;

  /// Creates a new FiatConversion
  ///
  /// [currencyData] The fiat currency data
  /// [exchangeRate] The exchange rate between Bitcoin and this fiat currency
  FiatConversion(this.currencyData, this.exchangeRate) {
    _logger.fine('Created FiatConversion for ${currencyData.id} with rate $exchangeRate');
  }

  /// Gets the logo path for the currency
  String get logoPath {
    final String? symbol = currencyData.info.symbol?.grapheme;

    switch (symbol) {
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

  /// Converts a fiat amount to satoshis
  ///
  /// [fiatAmount] The amount in fiat currency
  /// Returns the equivalent amount in satoshis
  int fiatToSat(double fiatAmount) {
    final int satoshis = (fiatAmount / exchangeRate * PaymentConstants.satoshisPerBitcoin).round();
    _logger.fine('Converting $fiatAmount ${currencyData.id} to $satoshis satoshis');
    return satoshis;
  }

  /// Gets a regex pattern that matches valid input for this currency
  RegExp get whitelistedPattern => currencyData.info.fractionSize == 0
      ? RegExp(r'\d+')
      : RegExp('^\\d+[.,]?\\d{0,${currencyData.info.fractionSize}}');

  /// Converts satoshis to fiat amount
  ///
  /// [satoshies] The amount in satoshis
  /// Returns the equivalent amount in fiat currency
  double satToFiat(int satoshies) {
    final double fiatAmount = satoshies.toDouble() / PaymentConstants.satoshisPerBitcoin * exchangeRate;
    _logger.fine('Converting $satoshies satoshis to $fiatAmount ${currencyData.id}');
    return fiatAmount;
  }

  /// Formats a satoshi amount as fiat currency
  ///
  /// [amount] The amount in satoshis
  /// [includeDisplayName] Whether to include the currency code (e.g., "USD")
  /// [addCurrencySymbol] Whether to add the currency symbol (e.g., "$")
  /// [removeTrailingZeros] Whether to remove trailing zeros
  /// Returns a formatted string representation of the fiat amount
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

  /// Formats a fiat amount according to locale and currency rules
  ///
  /// [fiatAmount] The amount in fiat currency
  /// [includeDisplayName] Whether to include the currency code (e.g., "USD")
  /// [addCurrencySymbol] Whether to add the currency symbol (e.g., "$")
  /// [removeTrailingZeros] Whether to remove trailing zeros
  /// Returns a formatted string representation of the fiat amount
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
      final NumberFormat formatter = CurrencyFormatter().getFormatter();
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

  /// Gets the conversion rate from sat to fiat (1 sat = X fiat)
  double get satConversionRate => 1 / exchangeRate * PaymentConstants.satoshisPerBitcoin;

  /// Gets locale overrides for a given locale tag or language code
  ///
  /// [languageTag] The full locale tag (e.g., "en-US")
  /// [languageCode] The language code (e.g., "en")
  /// Returns locale overrides if available, null otherwise
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
