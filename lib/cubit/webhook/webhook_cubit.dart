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
      (GetInfoResponse getInfoResponse) => refreshWebhooks(walletInfo: getInfoResponse.walletInfo),
    );
  }

  Future<void> refreshWebhooks({WalletInfo? walletInfo, String? username}) async {
    _logger.info('Refreshing webhooks');
    emit(WebhookState(isLoading: true));
    try {
      walletInfo = walletInfo ?? (await _breezSdkLiquid.instance?.getInfo())?.walletInfo;
      if (walletInfo != null) {
        await _registerWebhooks(walletInfo, username: username);
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

  Future<void> _registerWebhooks(WalletInfo walletInfo, {String? username}) async {
    try {
      final String webhookUrl = await _generateWebhookURL();
      await _breezSdkLiquid.instance?.registerWebhook(webhookUrl: webhookUrl);
      _logger.info('SDK webhook registered: $webhookUrl');
      await _registerLnurlpay(walletInfo, webhookUrl, username: username);
    } catch (err) {
      _logger.warning('Failed to register webhooks: $err');
      emit(state.copyWith(lnurlPayErrorTitle: 'Failed to register webhooks:', lnurlPayError: err.toString()));
      rethrow;
    }
  }

  // TODO(erdemyerebasmaz): Make this a public method so that it can be used to customize LN Addresses
  // TODO(erdemyerebasmaz): Currently the only endpoint generates a webhook URL & registers to it beforehand, which is not necessary for customizing username
  Future<void> _registerLnurlpay(
    WalletInfo walletInfo,
    String webhookUrl, {
    String? username,
  }) async {
    final String? lastUsedLnurlPay = await _breezPreferences.getLnUrlPayKey();
    if (lastUsedLnurlPay != null && lastUsedLnurlPay != webhookUrl) {
      await _invalidateLnurlPay(walletInfo, lastUsedLnurlPay);
    }
    // TODO(erdemyerebasmaz): Utilize user's username(only when user has created a new wallet)
    // TODO(erdemyerebasmaz): Handle multiple device setup cases
    String? lnAddressUsername = username ?? await _breezPreferences.getProfileName();
    lnAddressUsername = lnAddressUsername?.replaceAll(' ', '');
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String optionalUsernameKey = lnAddressUsername != null ? '-$lnAddressUsername' : '';
    final SignMessageRequest req =
        SignMessageRequest(message: '$currentTime-$webhookUrl$optionalUsernameKey');
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
          username: lnAddressUsername,
          signature: signMessageRes.signature,
        ).toJson(),
      ),
    );
    if (jsonResponse.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(jsonResponse.body);
      final String lnurl = data['lnurl'];
      final String lnAddress = data.containsKey('lightning_address') ? data['lightning_address'] : '';
      _logger.info('lnurlpay webhook registered: $webhookUrl, lnurl = $lnurl, lnAddress = $lnAddress');
      await _breezPreferences.setLnUrlPayKey(webhookUrl);
      emit(WebhookState(lnurlPayUrl: lnurl, lnAddress: lnAddress));
    } else {
      // TODO(erdemyerebasmaz): Handle username conflicts(only when user has created a new wallet)
      // Add a random four-digit identifier, a discriminator, as a suffix if user's username is taken(~1/600 probability of conflict)
      // Add a retry & randomizer logic until first registration succeeds
      // TODO(erdemyerebasmaz): Handle custom username conflicts
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
