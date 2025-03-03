import 'package:l_breez/utils/utils.dart';

class BitcoinCurrency extends Object {
  final String tickerSymbol;
  static const BitcoinCurrency btc = BitcoinCurrency._internal('BTC');
  static const BitcoinCurrency sat = BitcoinCurrency._internal('SAT');
  static final List<BitcoinCurrency> currencies =
      List<BitcoinCurrency>.unmodifiable(<BitcoinCurrency>[btc, sat]);

  const BitcoinCurrency._internal(this.tickerSymbol);

  factory BitcoinCurrency.fromTickerSymbol(String tickerSymbol) {
    return currencies.firstWhere(
      (BitcoinCurrency c) => c.tickerSymbol.toUpperCase() == tickerSymbol.toUpperCase(),
    );
  }

  String format(
    int sat, {
    bool includeCurrencySymbol = false,
    bool includeDisplayName = true,
    bool removeTrailingZeros = false,
    bool userInput = false,
  }) =>
      BitcoinCurrencyFormatter().format(
        sat,
        this,
        addCurrencySymbol: includeCurrencySymbol,
        addCurrencySuffix: includeDisplayName,
        removeTrailingZeros: removeTrailingZeros,
        userInput: userInput,
      );

  int parse(String amountStr) => BitcoinCurrencyFormatter().parse(amountStr, this);

  int parseToInt(
    String amountStr, {
    int def = 0,
  }) {
    int value;
    try {
      value = parse(amountStr).toInt();
    } catch (e) {
      return def;
    }
    return value;
  }

  int toSats(double amount) => BitcoinCurrencyFormatter().toSats(amount, this);

  String get displayName => tickerSymbol.toLowerCase() == 'sat' ? 'sats' : tickerSymbol;

  String get symbol {
    switch (tickerSymbol) {
      case 'BTC':
        return '₿';
      case 'SAT':
        return 'Ş';
      default:
        return '₿';
    }
  }

  RegExp get whitelistedPattern {
    switch (tickerSymbol) {
      case 'BTC':
        return RegExp('^\\d+[.,]?\\d{0,8}');
      case 'SAT':
        return RegExp(r'\d+');
      default:
        return RegExp('^\\d+[.,]?\\d{0,8}');
    }
  }

  double get satConversionRate => this == sat ? 1.0 : 100000000;
}
