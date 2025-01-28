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

  Future<String> generateWebhookUrl() async {
    _logger.info('Generating webhook URL');
    final String? token = await _notificationsClient.getToken();
    if (token == null) {
      _logger.severe('Failed to get notification token');
      throw GenerateWebhookUrlException('Failed to get notification token');
    }

    final String platform = _getPlatform();
    final String webhookUrl = '$_notifierServiceURL/api/v1/notify?platform=$platform&token=$token';
    _logger.info('Generated webhook URL: $webhookUrl');

    return webhookUrl;
  }

  String _getPlatform() {
    _logger.fine('Determining platform');
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    }
    _logger.severe('Unsupported platform: $defaultTargetPlatform');
    throw GenerateWebhookUrlException('Platform not supported');
  }

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
}
