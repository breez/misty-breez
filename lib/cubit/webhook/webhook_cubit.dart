import 'dart:convert';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/webhook/webhook_state.dart';
import 'package:breez_preferences/breez_preferences.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class WebhookCubit extends Cubit<WebhookState> {
  static const notifierServiceURL = "https://notifier.breez.technology";
  static const lnurlServiceURL = "https://breez.fun";

  final _log = Logger("WebhookCubit");

  final BreezSDKLiquid _liquidSDK;
  final BreezPreferences _breezPreferences;
  final NotificationsClient _notifications;

  WebhookCubit(
    this._liquidSDK,
    this._breezPreferences,
    this._notifications,
  ) : super(WebhookState()) {
    _liquidSDK.walletInfoStream
        .first
        .then((walletInfo) => refreshLnurlPay(walletInfo: walletInfo));
  }

  Future refreshLnurlPay({GetInfoResponse? walletInfo}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final getInfoResponse = walletInfo ?? await _liquidSDK.instance?.getInfo();
      if (getInfoResponse != null) {
        await _registerWebhooks(getInfoResponse);
      } else {
        throw Exception("Node state is empty");
      }
    } catch (err) {
      _log.warning("Failed to refresh lnurlpay: $err");
      emit(state.copyWith(lnurlPayError: err.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future _registerWebhooks(GetInfoResponse walletInfo) async {
    try {
      String webhookUrl = await _generateWebhookURL();
      await _liquidSDK.instance?.registerWebhook(webhookUrl: webhookUrl);
      _log.info("SDK webhook registered: $webhookUrl");
      final lnurl = await _registerLnurlpay(walletInfo, webhookUrl);
      emit(state.copyWith(lnurlPayUrl: lnurl));
    } catch (err) {
      _log.warning("Failed to register webhooks: $err");
      emit(state.copyWith(lnurlPayError: err.toString()));
      rethrow;
    }
  }

  Future<String> _registerLnurlpay(
    GetInfoResponse walletInfo,
    String webhookUrl,
  ) async {
    final lastUsedLnurlPay = await _breezPreferences.getLnUrlPayKey();
    if (lastUsedLnurlPay != null && lastUsedLnurlPay != webhookUrl) {
      await _invalidateLnurlPay(walletInfo, lastUsedLnurlPay);
    }
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final req = SignMessageRequest(message: "$currentTime-$webhookUrl");
    final signMessageRes = await _liquidSDK.instance?.signMessage(req: req);
    if (signMessageRes == null) {
      throw Exception("Missing signature");
    }
    final lnurlWebhookUrl = "$lnurlServiceURL/lnurlpay/${walletInfo.pubkey}";
    final uri = Uri.parse(lnurlWebhookUrl);
    final jsonResponse = await http.post(
      uri,
      body: jsonEncode(
        AddWebhookRequest(
          time: currentTime,
          webhookUrl: webhookUrl,
          signature: signMessageRes.signature,
        ).toJson(),
      ),
    );
    if (jsonResponse.statusCode == 200) {
      final data = jsonDecode(jsonResponse.body);
      final lnurl = data['lnurl'];
      _log.info("lnurlpay webhook registered: $webhookUrl, lnurl = $lnurl");
      await _breezPreferences.setLnUrlPayKey(webhookUrl);
      return lnurl;
    } else {
      throw jsonResponse.body;
    }
  }

  Future<void> _invalidateLnurlPay(
    GetInfoResponse walletInfo,
    String toInvalidate,
  ) async {
    final lnurlWebhookUrl = "$lnurlServiceURL/lnurlpay/${walletInfo.pubkey}";
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final req = SignMessageRequest(message: "$currentTime-$toInvalidate");
    final signMessageRes = await _liquidSDK.instance?.signMessage(req: req);
    if (signMessageRes == null) {
      throw Exception("Missing signature");
    }
    final uri = Uri.parse(lnurlWebhookUrl);
    final response = await http.delete(
      uri,
      body: jsonEncode(
        RemoveWebhookRequest(
          time: currentTime,
          webhookUrl: toInvalidate,
          signature: signMessageRes.signature,
        ).toJson(),
      ),
    );
    _log.info("invalidate lnurl pay response: ${response.statusCode}");
    await _breezPreferences.resetLnUrlPayKey();
  }

  Future<String> _generateWebhookURL() async {
    final token = await _notifications.getToken();
    _log.info("Retrieved token, registering…");
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? "ios"
        : defaultTargetPlatform == TargetPlatform.android
            ? "android"
            : "";
    if (platform.isEmpty) {
      throw Exception("Notifications for platform is not supported");
    }
    return "$notifierServiceURL/api/v1/notify?platform=$platform&token=$token";
  }
}
