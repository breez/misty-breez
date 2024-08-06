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

final _log = Logger("PaymentLimitsCubit");

class PaymentLimitsCubit extends Cubit<PaymentLimitsState> {
  final BreezSDKLiquid _liquidSdk;

  PaymentLimitsCubit(this._liquidSdk) : super(PaymentLimitsState.initial()) {
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
    _liquidSdk.walletInfoStream.first.then((walletInfo) {
      fetchLightningLimits();
      fetchOnchainLimits();
    });
  }

  @override
  Future<void> close() {
    fgBgEventsStreamSubscription?.cancel();
    return super.close();
  }

  Future<LightningPaymentLimitsResponse> fetchLightningLimits() async {
    try {
      final lightningPaymentLimits = await _liquidSdk.instance!.fetchLightningLimits();
      emit(state.copyWith(lightningPaymentLimits: lightningPaymentLimits, errorMessage: ""));
      return lightningPaymentLimits;
    } catch (e) {
      _log.severe("fetchLightningLimits error", e);
      final texts = getSystemAppLocalizations();
      emit(state.copyWith(lightningPaymentLimits: null, errorMessage: extractExceptionMessage(e, texts)));
      rethrow;
    }
  }

  Future<OnchainPaymentLimitsResponse> fetchOnchainLimits() async {
    try {
      final onchainPaymentLimits = await _liquidSdk.instance!.fetchOnchainLimits();
      emit(state.copyWith(onchainPaymentLimits: onchainPaymentLimits, errorMessage: ""));
      return onchainPaymentLimits;
    } catch (e) {
      _log.severe("fetchOnchainLimits error", e);
      final texts = getSystemAppLocalizations();
      emit(state.copyWith(onchainPaymentLimits: null, errorMessage: extractExceptionMessage(e, texts)));
      rethrow;
    }
  }

  @override
  void emit(PaymentLimitsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }
}
