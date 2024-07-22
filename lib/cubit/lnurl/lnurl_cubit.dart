library lnurl_cubit;

import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/lnurl/lnurl_state.dart';
import 'package:l_breez/cubit/model/src/payment/payment_error.dart';
import 'package:logging/logging.dart';

export 'lnurl_state.dart';

class LnUrlCubit extends Cubit<LnUrlState> {
  final _log = Logger("LnUrlCubit");
  final BreezSDKLiquid _liquidSdk;

  LnUrlCubit(this._liquidSdk) : super(LnUrlState.initial());

  Future<LnUrlWithdrawResult> lnurlWithdraw({
    required LnUrlWithdrawRequest req,
  }) async {
    try {
      return await _liquidSdk.instance!.lnurlWithdraw(req: req);
    } catch (e) {
      _log.severe("lnurlWithdraw error", e);
      rethrow;
    }
  }

  Future<LnUrlPayResult> lnurlPay({
    required LnUrlPayRequest req,
  }) async {
    try {
      return await _liquidSdk.instance!.lnurlPay(req: req);
    } catch (e) {
      _log.severe("lnurlPay error", e);
      rethrow;
    }
  }

  Future<LnUrlCallbackStatus> lnurlAuth({
    required LnUrlAuthRequestData reqData,
  }) async {
    try {
      return await _liquidSdk.instance!.lnurlAuth(reqData: reqData);
    } catch (e) {
      _log.severe("lnurlAuth error", e);
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
    var limits = outgoing ? lightningLimits.send : lightningLimits.receive;
    if (amount > limits.maxSat) {
      throw PaymentExceededLimitError(limits.maxSat.toInt());
    }
    if (amount < limits.minSat) {
      throw PaymentBelowLimitError(limits.minSat.toInt());
    }
  }
}
