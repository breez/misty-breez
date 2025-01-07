import 'dart:convert';

import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:http/http.dart' as http;
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

export 'webhook_state.dart';

final Logger _logger = Logger('WebhookCubit');

class WebhookCubit extends Cubit<WebhookState> {
  static const String notifierServiceURL = 'https://notifier.breez.technology';
  static const String lnurlServiceURL = 'https://breez.fun';

  final BreezSDKLiquid _breezSdkLiquid;
  final BreezPreferences _breezPreferences;
  final NotificationsClient _notifications;

  WebhookCubit(
    this._breezSdkLiquid,
    this._breezPreferences,
    this._notifications,
  ) : super(WebhookState()) {
    _breezSdkLiquid.walletInfoStream.first.then(
      (GetInfoResponse getInfoResponse) => refreshLnurlPay(getInfoResponse: getInfoResponse),
    );
  }

  Future<void> refreshLnurlPay({GetInfoResponse? getInfoResponse}) async {
    _logger.info('Refreshing Lightning Address');
    emit(WebhookState(isLoading: true));
    try {
      getInfoResponse = getInfoResponse ?? await _breezSdkLiquid.instance?.getInfo();
      if (getInfoResponse != null) {
        await _registerWebhooks(getInfoResponse.walletInfo);
      } else {
        throw Exception('Unable to retrieve wallet information.');
      }
    } catch (err) {
      _logger.warning('Failed to refresh lnurlpay: $err');
      emit(
        state.copyWith(
          lnurlPayErrorTitle: 'Failed to refresh Lightning Address:',
          lnurlPayError: err.toString(),
        ),
      );
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _registerWebhooks(WalletInfo walletInfo) async {
    try {
      final String webhookUrl = await _generateWebhookURL();
      await _breezSdkLiquid.instance?.registerWebhook(webhookUrl: webhookUrl);
      _logger.info('SDK webhook registered: $webhookUrl');
      final String lnurl = await _registerLnurlpay(walletInfo, webhookUrl);
      emit(WebhookState(lnurlPayUrl: lnurl));
    } catch (err) {
      _logger.warning('Failed to register webhooks: $err');
      emit(state.copyWith(lnurlPayErrorTitle: 'Failed to register webhooks:', lnurlPayError: err.toString()));
      rethrow;
    }
  }

  Future<String> _registerLnurlpay(
    WalletInfo walletInfo,
    String webhookUrl,
  ) async {
    final String? lastUsedLnurlPay = await _breezPreferences.getLnUrlPayKey();
    if (lastUsedLnurlPay != null && lastUsedLnurlPay != webhookUrl) {
      await _invalidateLnurlPay(walletInfo, lastUsedLnurlPay);
    }
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final SignMessageRequest req = SignMessageRequest(message: '$currentTime-$webhookUrl');
    final SignMessageResponse? signMessageRes = _breezSdkLiquid.instance?.signMessage(req: req);
    if (signMessageRes == null) {
      throw Exception('Missing signature');
    }
    final String lnurlWebhookUrl = '$lnurlServiceURL/lnurlpay/${walletInfo.pubkey}';
    final Uri uri = Uri.parse(lnurlWebhookUrl);
    final http.Response jsonResponse = await http.post(
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
      final Map<String, dynamic> data = jsonDecode(jsonResponse.body);
      final String lnurl = data['lnurl'];
      _logger.info('lnurlpay webhook registered: $webhookUrl, lnurl = $lnurl');
      await _breezPreferences.setLnUrlPayKey(webhookUrl);
      return lnurl;
    } else {
      throw jsonResponse.body;
    }
  }

  Future<void> _invalidateLnurlPay(
    WalletInfo walletInfo,
    String toInvalidate,
  ) async {
    final String lnurlWebhookUrl = '$lnurlServiceURL/lnurlpay/${walletInfo.pubkey}';
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final SignMessageRequest req = SignMessageRequest(message: '$currentTime-$toInvalidate');
    final SignMessageResponse? signMessageRes = _breezSdkLiquid.instance?.signMessage(req: req);
    if (signMessageRes == null) {
      throw Exception('Missing signature');
    }
    final Uri uri = Uri.parse(lnurlWebhookUrl);
    final http.Response response = await http.delete(
      uri,
      body: jsonEncode(
        RemoveWebhookRequest(
          time: currentTime,
          webhookUrl: toInvalidate,
          signature: signMessageRes.signature,
        ).toJson(),
      ),
    );
    _logger.info('invalidate lnurl pay response: ${response.statusCode}');
    await _breezPreferences.resetLnUrlPayKey();
  }

  Future<String> _generateWebhookURL() async {
    final String? token = await _notifications.getToken();
    _logger.info('Retrieved token, registering…');
    final String platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : '';
    if (platform.isEmpty) {
      throw Exception('Notifications for platform is not supported');
    }
    return '$notifierServiceURL/api/v1/notify?platform=$platform&token=$token';
  }
}
