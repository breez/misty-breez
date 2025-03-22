import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

export 'lnurl_state.dart';

final Logger _logger = Logger('LnUrlCubit');

class LnUrlCubit extends Cubit<LnUrlState> {
  final BreezSDKLiquid _breezSdkLiquid;

  LnUrlCubit(this._breezSdkLiquid) : super(LnUrlState.initial());

  Future<LnUrlWithdrawResult> lnurlWithdraw({
    required LnUrlWithdrawRequest req,
  }) async {
    try {
      return await _breezSdkLiquid.instance!.lnurlWithdraw(req: req);
    } catch (e) {
      _logger.severe('lnurlWithdraw error', e);
      rethrow;
    }
  }

  Future<PrepareLnUrlPayResponse> prepareLnurlPay({
    required PrepareLnUrlPayRequest req,
  }) async {
    try {
      return await _breezSdkLiquid.instance!.prepareLnurlPay(req: req);
    } catch (e) {
      _logger.severe('prepareLnurlPay error', e);
      rethrow;
    }
  }

  Future<LnUrlPayResult> lnurlPay({
    required LnUrlPayRequest req,
  }) async {
    try {
      return await _breezSdkLiquid.instance!.lnurlPay(req: req);
    } catch (e) {
      _logger.severe('lnurlPay error', e);
      rethrow;
    }
  }

  Future<LnUrlCallbackStatus> lnurlAuth({
    required LnUrlAuthRequestData reqData,
  }) async {
    try {
      return await _breezSdkLiquid.instance!.lnurlAuth(reqData: reqData);
    } catch (e) {
      _logger.severe('lnurlAuth error', e);
      rethrow;
    }
  }

  void validateLnUrlPayment(
    BigInt amount,
    bool outgoing,
    LightningPaymentLimitsResponse lightningLimits,
    int balance,
  ) {
    if (outgoing && amount.toInt() > balance) {
      throw const InsufficientLocalBalanceError();
    }
    final Limits limits = outgoing ? lightningLimits.send : lightningLimits.receive;
    if (amount > limits.maxSat) {
      throw PaymentExceedsLimitError(limits.maxSat.toInt());
    }
    if (amount < limits.minSat) {
      throw PaymentBelowLimitError(limits.minSat.toInt());
    }
  }
}
