import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/utils/utils.dart';

final Logger _logger = Logger('LnUrlWebhookService');

/// Service responsible for managing webhooks for Lightning Network payments.
///
/// Handles webhook registration with the Breez SDK and generation of
/// webhook URLs for receiving payment notifications.
class LnUrlWebhookService {
  /// Default timeout for SDK operations.
  static const Duration _defaultTimeout = Duration(seconds: 20);

  final BreezSDKLiquid _breezSdkLiquid;
  final WebhookGenerator _generator;

  /// Creates a new [LnUrlWebhookService] instance.
  ///
  /// Requires [BreezSDKLiquid] for webhook registration,
  /// [NotificationsClient] for notification token management and
  /// [PermissionsCubit] for notification permission management.
  LnUrlWebhookService(
    this._breezSdkLiquid,
    NotificationsClient notificationsClient,
    PermissionsCubit permissionsCubit,
  ) : _generator = WebhookGenerator(_logger, notificationsClient, permissionsCubit);

  /// Registers a webhook with the Breez SDK.
  ///
  /// The [webhookUrl] is the URL that will receive payment notifications.
  /// Throws [RegisterWebhookException] if registration fails.
  Future<void> register(String webhookUrl, {Duration timeout = _defaultTimeout}) async {
    _logger.info('Registering webhook: $webhookUrl');

    await executeWithRetry<void>(
      () => _registerWebhook(webhookUrl, timeout),
      operationName: 'register webhook',
      maxRetries: 3,
      logger: _logger,
    );

    _logger.info('Successfully registered webhook');
  }

  /// Registers a webhook with timeout handling.
  Future<void> _registerWebhook(String webhookUrl, Duration timeout) async {
    try {
      final BreezSdkLiquid? sdk = _breezSdkLiquid.instance;
      if (sdk == null) {
        throw RegisterWebhookException('Breez SDK not initialized');
      }

      await sdk
          .registerWebhook(webhookUrl: webhookUrl)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException('Webhook registration timed out after ${timeout.inSeconds} seconds');
            },
          );
    } catch (e, stackTrace) {
      _logger.severe('Failed to register webhook', e, stackTrace);
      throw RegisterWebhookException('Failed to register webhook: $e');
    }
  }

  Future<String> generateWebhookUrl() async {
    return _generator.generateUrl();
  }
}
