import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter/foundation.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('WebhookService');

class WebhookService {
  static const String _notifierServiceURL = 'https://notifier.breez.technology';

  final BreezSDKLiquid _breezSdkLiquid;
  final NotificationsClient _notificationsClient;

  WebhookService(this._breezSdkLiquid, this._notificationsClient);

  Future<void> register(String webhookUrl) async {
    try {
      _logger.info('Registering webhook: $webhookUrl');
      await _breezSdkLiquid.instance?.registerWebhook(webhookUrl: webhookUrl);
      _logger.info('Successfully registered webhook');
    } catch (e, stackTrace) {
      _logger.severe('Failed to register webhook', e, stackTrace);
      throw RegisterWebhookException('Failed to register webhook: $e');
    }
  }

  Future<String> generateWebhookUrl() async {
    try {
      _logger.info('Generating webhook URL');
      final String platform = _getPlatform();
      final String token = await _getToken();
      final String webhookUrl = '$_notifierServiceURL/api/v1/notify?platform=$platform&token=$token';
      _logger.info('Generated webhook URL: $webhookUrl');
      return webhookUrl;
    } catch (e) {
      _logger.severe('Failed to generate webhook URL', e);
      throw GenerateWebhookUrlException(e.toString());
    }
  }

  String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    }
    _logger.severe('Unsupported platform: $defaultTargetPlatform');
    throw GenerateWebhookUrlException('Platform not supported');
  }

  Future<String> _getToken() async {
    final String? token = await _notificationsClient.getToken();
    if (token != null) {
      return token;
    }
    _logger.severe('Failed to get notification token');
    throw GenerateWebhookUrlException('Failed to get notification token');
  }
}
