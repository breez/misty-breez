library payment_limits_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/payment_limits/payment_limits_state.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

export 'payment_limits_state.dart';

class PaymentLimitsCubit extends Cubit<PaymentLimitsState> {
  final _log = Logger("PaymentLimitsCubit");
  final BreezSDKLiquid _liquidSdk;

  PaymentLimitsCubit(this._liquidSdk) : super(PaymentLimitsState.initial()) {
    _fetchPaymentLimits();
    _refreshPaymentLimitsOnResume();
  }

  void _refreshPaymentLimitsOnResume() {
    FGBGEvents.stream.listen((event) {
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

  Future<LightningPaymentLimitsResponse> fetchLightningLimits() async {
    try {
      final lightningPaymentLimits = await _liquidSdk.instance!.fetchLightningLimits();
      _emitState(state.copyWith(lightningPaymentLimits: lightningPaymentLimits, errorMessage: ""));
      return lightningPaymentLimits;
    } catch (e) {
      _log.severe("fetchLightningLimits error", e);
      final texts = getSystemAppLocalizations();
      _emitState(
          state.copyWith(lightningPaymentLimits: null, errorMessage: extractExceptionMessage(e, texts)));
      rethrow;
    }
  }

  Future<OnchainPaymentLimitsResponse> fetchOnchainLimits() async {
    try {
      final onchainPaymentLimits = await _liquidSdk.instance!.fetchOnchainLimits();
      _emitState(state.copyWith(onchainPaymentLimits: onchainPaymentLimits, errorMessage: ""));
      return onchainPaymentLimits;
    } catch (e) {
      _log.severe("fetchOnchainLimits error", e);
      final texts = getSystemAppLocalizations();
      _emitState(state.copyWith(onchainPaymentLimits: null, errorMessage: extractExceptionMessage(e, texts)));
      rethrow;
    }
  }

  void _emitState(PaymentLimitsState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}