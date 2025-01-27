import 'dart:convert';

import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:http/http.dart' as http;
import 'package:l_breez/cubit/webhook/webhook_state.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LnUrlPayService');

class LnUrlPayService {
  static const String lnurlServiceURL = 'https://breez.fun';

  final BreezSDKLiquid _breezSdkLiquid;
  final BreezPreferences _breezPreferences;

  LnUrlPayService(this._breezSdkLiquid, this._breezPreferences);

  Future<Map<String, String>> registerLnurlpay(
    WalletInfo walletInfo,
    String webhookUrl, {
    String? username,
  }) async {
    final String pubKey = walletInfo.pubkey;

    await _invalidatePreviousWebhookIfNeeded(pubKey, webhookUrl);

    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // TODO(erdemyerebasmaz): Utilize user's username(only when user has created a new wallet)
    // TODO(erdemyerebasmaz): Handle multiple device setup cases
    final String? lnAddressUsername =
        (username ?? await _breezPreferences.getProfileName())?.replaceAll(' ', '');

    final SignMessageResponse? signMessageRes = await _generateSignature(
      webhookUrl: webhookUrl,
      currentTime: currentTime,
      lnAddressUsername: lnAddressUsername,
    );

    if (signMessageRes == null) {
      throw Exception('Missing signature');
    }

    final Map<String, String> response = await _postWebhookRegistrationRequest(
      pubKey: pubKey,
      webhookUrl: webhookUrl,
      currentTime: currentTime,
      lnAddressUsername: lnAddressUsername,
      signature: signMessageRes.signature,
    );

    await setLnUrlPayKey(webhookUrl: webhookUrl);
    return response;
  }

  Future<void> _invalidatePreviousWebhookIfNeeded(String pubKey, String webhookUrl) async {
    final String? lastUsedLnurlPay = await getLnUrlPayKey();
    if (lastUsedLnurlPay != null && lastUsedLnurlPay != webhookUrl) {
      await _invalidateLnurlPay(pubKey, lastUsedLnurlPay);
    }
  }

  Future<SignMessageResponse?> _generateSignature({
    required String webhookUrl,
    required int currentTime,
    String? lnAddressUsername,
  }) async {
    final String username = lnAddressUsername?.isNotEmpty == true ? '-$lnAddressUsername' : '';
    final String message = '$currentTime-$webhookUrl$username';

    final SignMessageRequest req = SignMessageRequest(message: message);
    return _breezSdkLiquid.instance?.signMessage(req: req);
  }

  Future<Map<String, String>> _postWebhookRegistrationRequest({
    required String pubKey,
    required String webhookUrl,
    required int currentTime,
    required String signature,
    String? lnAddressUsername,
  }) async {
    final String lnurlWebhookUrl = '$lnurlServiceURL/lnurlpay/$pubKey';
    final Uri uri = Uri.parse(lnurlWebhookUrl);

    final http.Response jsonResponse = await http.post(
      uri,
      body: jsonEncode(
        AddWebhookRequest(
          time: currentTime,
          webhookUrl: webhookUrl,
          username: lnAddressUsername,
          signature: signature,
        ).toJson(),
      ),
    );

    if (jsonResponse.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(jsonResponse.body);
      final String lnurl = data['lnurl'];
      final String lnAddress = data.containsKey('lightning_address') ? data['lightning_address'] : '';
      _logger.info('Registered LnUrl Webhook: $webhookUrl, lnurl = $lnurl, lnAddress = $lnAddress');
      return <String, String>{
        'lnurl': lnurl,
        'lnAddress': lnAddress,
      };
    } else {
      // TODO(erdemyerebasmaz): Handle username conflicts(only when user has created a new wallet)
      // Add a random four-digit identifier, a discriminator, as a suffix if user's username is taken(~1/600 probability of conflict)
      // Add a retry & randomizer logic until first registration succeeds
      // TODO(erdemyerebasmaz): Handle custom username conflicts
      throw Exception('Failed to register LnUrl Webhook: ${jsonResponse.body}');
    }
  }

  Future<Map<String, String>> updateLnAddressUsername(WalletInfo walletInfo, String username) async {
    final String? webhookUrl = await getLnUrlPayKey();
    if (webhookUrl == null) {
      throw Exception('Failed to retrieve registered webhook.');
    }
    return await registerLnurlpay(walletInfo, webhookUrl, username: username);
  }

  Future<void> _invalidateLnurlPay(String pubKey, String toInvalidate) async {
    final String lnurlWebhookUrl = '$lnurlServiceURL/lnurlpay/$pubKey';
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
    await resetLnUrlPayKey();
    await resetLnAddressUsername();
  }

  Future<void> setLnUrlPayKey({required String webhookUrl}) async {
    return await _breezPreferences.setLnUrlPayKey(webhookUrl);
  }

  Future<String?> getLnUrlPayKey() async {
    return await _breezPreferences.getLnUrlPayKey();
  }

  Future<void> resetLnUrlPayKey() async {
    return await _breezPreferences.resetLnUrlPayKey();
  }

  Future<void> setLnAddressUsername({required String lnAddressUsername}) async {
    return await _breezPreferences.setLnAddressUsername(lnAddressUsername);
  }

  Future<String?> getLnAddressUsername() async {
    return await _breezPreferences.getLnAddressUsername();
  }

  Future<void> resetLnAddressUsername() async {
    return await _breezPreferences.resetLnAddressUsername();
  }
}
