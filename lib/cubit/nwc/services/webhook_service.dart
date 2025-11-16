import 'dart:convert';
import 'dart:io';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/utils/utils.dart';

final Logger _logger = Logger('NwcWebhookService');

class NwcWebhookService {
  final WebhookGenerator _generator;
  final BreezSDKLiquid _breezSdkLiquid;
  final http.Client _client = http.Client();

  NwcWebhookService(
    this._breezSdkLiquid,
    NotificationsClient notificationsClient,
    PermissionsCubit permissionsCubit,
  ) : _generator = WebhookGenerator(_logger, notificationsClient, permissionsCubit);

  Future<void> register(RegisterNwcWebhookRequest req) async {
    _logger.info('Registering webhook: ${req.webhookUrl} for appPubkey ${req.appPubkey}');
    await executeWithRetry<void>(
      () => _registerWebhook(req),
      operationName: 'register webhook',
      maxRetries: 3,
      logger: _logger,
    );
    _logger.info('Successfully registered webhook');
  }

  Future<void> _registerWebhook(RegisterNwcWebhookRequest body) async {
    try {
      final BreezSdkLiquid? sdk = _breezSdkLiquid.instance;
      if (sdk == null) {
        throw RegisterWebhookException('Breez SDK not initialized');
      }
      final String walletPubkey = await sdk.getInfo().then((GetInfoResponse info) => info.walletInfo.pubkey);

      final Uri uri = Uri.parse('${WebhookConstants.nwcWebhooksEndpoint}/$walletPubkey');
      final Map<String, String> headers = <String, String>{'Content-Type': 'application/json'};
      final http.Response res = await _client.post(uri, body: jsonEncode(body.toJson()), headers: headers);
      if (res.statusCode != HttpStatus.ok) {
        throw RegisterWebhookException(
          'Failed to register webhook: server responded with error status. Response body: ${res.body}',
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to register webhook', e, stackTrace);
      throw RegisterWebhookException('Failed to register webhook: $e');
    }
  }

  Future<String> generateWebhookUrl() async {
    return _generator.generateUrl();
  }
}
