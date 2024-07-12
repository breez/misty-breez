import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/bloc/account/breez_sdk_liquid.dart';
import 'package:l_breez/bloc/lnurl/lnurl_state.dart';
import 'package:logging/logging.dart';

class LnUrlCubit extends Cubit<LnUrlState> {
  final _log = Logger("LnUrlCubit");
  final BreezSDKLiquid _liquidSdk;

  LnUrlCubit(this._liquidSdk) : super(LnUrlState.initial());

  Future<LightningPaymentLimitsResponse> fetchLightningLimits() async {
    try {
      final limits = await _liquidSdk.instance!.fetchLightningLimits();
      emit(state.copyWith(limits: limits));
      return limits;
    } catch (e) {
      _log.severe("fetchLightningLimits error", e);
      rethrow;
    }
  }

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
}
