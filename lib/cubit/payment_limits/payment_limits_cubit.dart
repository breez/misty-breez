library payment_limits_cubit;

import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/payment_limits/payment_limits_state.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

export 'payment_limits_state.dart';

final _logger = Logger("PaymentLimitsCubit");

class PaymentLimitsCubit extends Cubit<PaymentLimitsState> {
  final BreezSDKLiquid _breezSdkLiquid;

  PaymentLimitsCubit(this._breezSdkLiquid) : super(PaymentLimitsState.initial()) {
    _fetchPaymentLimits();
    _refreshPaymentLimitsOnResume();
  }

  StreamSubscription<FGBGType>? fgBgEventsStreamSubscription;

  void _refreshPaymentLimitsOnResume() {
    fgBgEventsStreamSubscription = FGBGEvents.stream.listen((event) {
      if (event == FGBGType.foreground) {
        _fetchPaymentLimits();
      }
    });
  }

  void _fetchPaymentLimits() {
    if (_breezSdkLiquid.instance != null) {
      _breezSdkLiquid.walletInfoStream.first.then((walletInfo) {
        fetchLightningLimits();
        fetchOnchainLimits();
      }).timeout(const Duration(seconds: 15), onTimeout: () {
        emit(state.copyWith(errorMessage: "Fetching payment network limits timed out."));
      });
    } else {
      emit(state.copyWith(errorMessage: "Breez SDK instance is not running"));
    }
  }

  @override
  Future<void> close() {
    fgBgEventsStreamSubscription?.cancel();
    return super.close();
  }

  Future<LightningPaymentLimitsResponse?> fetchLightningLimits() async {
    emit(state.copyWith(errorMessage: ""));
    if (_breezSdkLiquid.instance != null) {
      try {
        final lightningPaymentLimits = await _breezSdkLiquid.instance!.fetchLightningLimits();
        emit(state.copyWith(lightningPaymentLimits: lightningPaymentLimits, errorMessage: ""));
        return lightningPaymentLimits;
      } catch (e) {
        _logger.severe("fetchLightningLimits error", e);
        final texts = getSystemAppLocalizations();
        emit(state.copyWith(lightningPaymentLimits: null, errorMessage: extractExceptionMessage(e, texts)));
        rethrow;
      }
    } else {
      emit(state.copyWith(errorMessage: "Breez SDK instance is not running"));
      return null;
    }
  }

  Future<OnchainPaymentLimitsResponse?> fetchOnchainLimits() async {
    emit(state.copyWith(errorMessage: ""));
    if (_breezSdkLiquid.instance != null) {
      try {
        final onchainPaymentLimits = await _breezSdkLiquid.instance!.fetchOnchainLimits();
        emit(state.copyWith(onchainPaymentLimits: onchainPaymentLimits, errorMessage: ""));
        return onchainPaymentLimits;
      } catch (e) {
        _logger.severe("fetchOnchainLimits error", e);
        final texts = getSystemAppLocalizations();
        emit(state.copyWith(onchainPaymentLimits: null, errorMessage: extractExceptionMessage(e, texts)));
        rethrow;
      }
    } else {
      emit(state.copyWith(errorMessage: "Breez SDK instance is not running"));
      return null;
    }
  }

  @override
  void emit(PaymentLimitsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }
}
