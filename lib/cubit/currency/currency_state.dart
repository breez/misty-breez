import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/utils/utils.dart';

class CurrencyState {
  final List<String> preferredCurrencies;
  final String fiatId;
  final String bitcoinTicker;
  final Map<String, Rate> exchangeRates;
  final List<FiatCurrency> fiatCurrenciesData;

  CurrencyState({
    this.fiatCurrenciesData = const <FiatCurrency>[],
    this.exchangeRates = const <String, Rate>{},
    this.preferredCurrencies = const <String>['USD', 'EUR', 'GBP', 'JPY'],
    this.fiatId = 'USD',
    this.bitcoinTicker = 'SAT',
  });

  CurrencyState.initial() : this();

  CurrencyState copyWith({
    List<FiatCurrency>? fiatCurrenciesData,
    Map<String, Rate>? exchangeRates,
    String? fiatId,
    String? bitcoinTicker,
    List<String>? preferredCurrencies,
  }) {
    return CurrencyState(
      fiatCurrenciesData: fiatCurrenciesData ?? this.fiatCurrenciesData,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      preferredCurrencies: preferredCurrencies ?? this.preferredCurrencies,
      fiatId: fiatId ?? this.fiatId,
      bitcoinTicker: bitcoinTicker ?? this.bitcoinTicker,
    );
  }

  BitcoinCurrency get bitcoinCurrency => BitcoinCurrency.fromTickerSymbol(bitcoinTicker);

  FiatCurrency? get fiatCurrency => fiatById(fiatId);

  double? get fiatExchangeRate => exchangeRates[fiatId]?.value;

  bool get fiatEnabled => fiatCurrency != null && fiatExchangeRate != null;

  FiatCurrency? fiatById(String id) {
    for (FiatCurrency fc in fiatCurrenciesData) {
      if (fc.id == id) {
        return fc;
      }
    }
    return null;
  }

  FiatConversion? fiatConversion() {
    final FiatCurrency? currency = fiatCurrency;
    final double? exchange = fiatExchangeRate;
    if (currency != null && exchange != null) {
      return FiatConversion(currency, exchange);
    } else {
      return null;
    }
  }

  CurrencyState.fromJson(Map<String, dynamic> json)
      : preferredCurrencies = (json['preferredCurrencies'] as List<dynamic>).cast<String>(),
        exchangeRates = <String, Rate>{},
        fiatCurrenciesData = <FiatCurrency>[],
        fiatId = json['fiatId'],
        bitcoinTicker = json['bitcoinTicker'];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'preferredCurrencies': preferredCurrencies,
        'fiatId': fiatId,
        'bitcoinTicker': bitcoinTicker,
      };
}
