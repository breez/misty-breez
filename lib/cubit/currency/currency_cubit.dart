import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'currency_state.dart';

final Logger _logger = Logger('CurrencyCubit');

class CurrencyCubit extends Cubit<CurrencyState> with HydratedMixin<CurrencyState> {
  final BreezSDKLiquid breezSdkLiquid;

  CurrencyCubit(this.breezSdkLiquid) : super(CurrencyState.initial()) {
    hydrate();

    _initializeCurrencyCubit();
  }

  void _initializeCurrencyCubit() {
    breezSdkLiquid.getInfoResponseStream.first.then((GetInfoResponse getInfoResponse) {
      listFiatCurrencies();
      fetchExchangeRates();
    });
  }

  void listFiatCurrencies() {
    breezSdkLiquid.instance!.listFiatCurrencies().then((List<FiatCurrency> fiatCurrencies) {
      emit(
        state.copyWith(
          fiatCurrenciesData: _sortedFiatCurrenciesList(fiatCurrencies, state.preferredCurrencies),
        ),
      );
    });
  }

  List<FiatCurrency> _sortedFiatCurrenciesList(
    List<FiatCurrency> fiatCurrencies,
    List<String> preferredCurrencies,
  ) {
    final List<FiatCurrency> sorted = fiatCurrencies.toList();
    sorted.sort((FiatCurrency f1, FiatCurrency f2) {
      return f1.id.compareTo(f2.id);
    });

    // Then give precedence to the preferred items.
    for (String p in preferredCurrencies.reversed) {
      final int preferredIndex = sorted.indexWhere((FiatCurrency e) => e.id == p);
      if (preferredIndex >= 0) {
        final FiatCurrency preferred = sorted[preferredIndex];
        sorted.removeAt(preferredIndex);
        sorted.insert(0, preferred);
      }
    }
    return sorted;
  }

  Future<Map<String, Rate>> fetchExchangeRates() async {
    final List<Rate> rates = await breezSdkLiquid.instance!.fetchFiatRates();
    final Map<String, Rate> exchangeRates = rates.fold<Map<String, Rate>>(<String, Rate>{}, (
      Map<String, Rate> map,
      Rate rate,
    ) {
      map[rate.coin] = rate;
      return map;
    });
    emit(state.copyWith(exchangeRates: exchangeRates));
    return exchangeRates;
  }

  void setFiatId(String fiatId) {
    emit(state.copyWith(fiatId: fiatId));
  }

  void setPreferredCurrencies(List<String> preferredCurrencies) {
    emit(
      state.copyWith(
        fiatCurrenciesData: _sortedFiatCurrenciesList(state.fiatCurrenciesData, preferredCurrencies),
        preferredCurrencies: preferredCurrencies,
        fiatId: preferredCurrencies[0],
      ),
    );
  }

  void setBitcoinTicker(String bitcoinTicker) {
    emit(state.copyWith(bitcoinTicker: bitcoinTicker));
  }

  @override
  CurrencyState? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.severe('No stored data found.');
      return null;
    }

    try {
      final CurrencyState result = CurrencyState.fromJson(json);
      _logger.fine('Successfully hydrated with $result');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error hydrating: $e');
      _logger.fine('Stack trace: $stackTrace');
      return CurrencyState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(CurrencyState state) {
    try {
      final Map<String, dynamic> result = state.toJson();
      _logger.fine('Serialized: $result');
      return result;
    } catch (e) {
      _logger.severe('Error serializing: $e');
      return null;
    }
  }

  @override
  String get storagePrefix => defaultTargetPlatform == TargetPlatform.iOS ? 'xVa' : 'CurrencyCubit';
}
