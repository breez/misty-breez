import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('WebhookService');

class WebhookService {
  static const String notifierServiceURL = 'https://notifier.breez.technology';

  final BreezSDKLiquid _breezSdkLiquid;
  final NotificationsClient _notifications;

  WebhookService(this._breezSdkLiquid, this._notifications);

  Future<String> generateWebhookURL() async {
    final String? token = await _notifications.getToken();
    _logger.info('Retrieved token, generating webhook URL.');
    final String platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : '';
    if (platform.isEmpty) {
      throw Exception('Notifications for platform is not supported');
    }
    final String webhookUrl = '$notifierServiceURL/api/v1/notify?platform=$platform&token=$token';
    _logger.info('Generated webhook URL: $webhookUrl');
    return webhookUrl;
  }

  Future<void> registerWebhook(String webhookUrl) async {
    try {
      await _breezSdkLiquid.instance?.registerWebhook(webhookUrl: webhookUrl);
      _logger.info('Registered webhook: $webhookUrl');
    } catch (err) {
      _logger.warning('Failed to register webhook: $err');
      rethrow;
    }
  }
}
