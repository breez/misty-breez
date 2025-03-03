import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/utils.dart';
import 'package:logging/logging.dart';

export 'payment_limits_state.dart';

final Logger _logger = Logger('PaymentLimitsCubit');

class PaymentLimitsCubit extends Cubit<PaymentLimitsState> {
  final BreezSDKLiquid _breezSdkLiquid;

  PaymentLimitsCubit(this._breezSdkLiquid) : super(PaymentLimitsState.initial()) {
    _fetchPaymentLimits();
    _refreshPaymentLimitsOnResume();
  }

  StreamSubscription<FGBGType>? fgBgEventsStreamSubscription;

  void _refreshPaymentLimitsOnResume() {
    fgBgEventsStreamSubscription = FGBGEvents.instance.stream.listen((FGBGType event) {
      if (event == FGBGType.foreground) {
        _fetchPaymentLimits();
      }
    });
  }

  void _fetchPaymentLimits() {
    if (_breezSdkLiquid.instance != null) {
      _breezSdkLiquid.getInfoResponseStream.first.then((GetInfoResponse getInfoResponse) {
        fetchLightningLimits();
        fetchOnchainLimits();
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          emit(state.copyWith(errorMessage: 'Fetching payment network limits timed out.'));
        },
      );
    } else {
      emit(state.copyWith(errorMessage: 'Breez SDK instance is not running'));
    }
  }

  @override
  Future<void> close() {
    fgBgEventsStreamSubscription?.cancel();
    return super.close();
  }

  Future<LightningPaymentLimitsResponse?> fetchLightningLimits() async {
    emit(state.copyWith(errorMessage: ''));
    if (_breezSdkLiquid.instance != null) {
      try {
        final LightningPaymentLimitsResponse lightningPaymentLimits =
            await _breezSdkLiquid.instance!.fetchLightningLimits();
        emit(state.copyWith(lightningPaymentLimits: lightningPaymentLimits, errorMessage: ''));
        return lightningPaymentLimits;
      } catch (e) {
        _logger.severe('fetchLightningLimits error', e);
        final BreezTranslations texts = getSystemAppLocalizations();
        emit(state.copyWith(errorMessage: ExceptionHandler.extractMessage(e, texts)));
        rethrow;
      }
    } else {
      emit(state.copyWith(errorMessage: 'Breez SDK instance is not running'));
      return null;
    }
  }

  Future<OnchainPaymentLimitsResponse?> fetchOnchainLimits() async {
    emit(state.copyWith(errorMessage: ''));
    if (_breezSdkLiquid.instance != null) {
      try {
        final OnchainPaymentLimitsResponse onchainPaymentLimits =
            await _breezSdkLiquid.instance!.fetchOnchainLimits();
        emit(state.copyWith(onchainPaymentLimits: onchainPaymentLimits, errorMessage: ''));
        return onchainPaymentLimits;
      } catch (e) {
        _logger.severe('fetchOnchainLimits error', e);
        final BreezTranslations texts = getSystemAppLocalizations();
        emit(state.copyWith(errorMessage: ExceptionHandler.extractMessage(e, texts)));
        rethrow;
      }
    } else {
      emit(state.copyWith(errorMessage: 'Breez SDK instance is not running'));
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
