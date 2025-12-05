import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/constants/app_constants.dart';
import 'package:misty_breez/utils/futures/futures.dart';

class GenerateWebhookUrlException implements Exception {
  final String message;

  GenerateWebhookUrlException(this.message);

  @override
  String toString() => message;
}

class WebhookGenerator {
  /// Maximum number of retry attempts for operations.
  static const int _maxRetries = 3;

  /// Default cache duration for notification tokens.
  static const Duration _tokenCacheDuration = Duration(hours: 1);

  /// Platform string (ios, android) for webhook URL generation.
  String? _platformString;

  /// When the token was last cached.
  DateTime? _tokenCacheTime;

  /// Cached notification token to avoid repeated requests.
  String? _cachedToken;

  final Logger _logger;
  final NotificationsClient _notificationsClient;
  final PermissionsCubit _permissionsCubit;

  WebhookGenerator(this._logger, this._notificationsClient, this._permissionsCubit);

  /// Generates a webhook URL for receiving offline notifications.
  ///
  /// The URL includes the device platform and notification token.
  /// Throws [GenerateWebhookUrlException] if URL generation fails.
  Future<String> generateUrl() async {
    _logger.info('Generating webhook URL');

    try {
      final List<String> components = await Future.wait(<Future<String>>[_getPlatform(), _getToken()]);

      final String platform = components[0];
      final String token = components[1];

      final String webhookUrl =
          '${WebhookConstants.notifierServiceURL}/api/v1/notify?platform=$platform&token=$token';
      _logger.info('Generated webhook URL: $webhookUrl');

      return webhookUrl;
    } catch (e, stackTrace) {
      _logger.severe('Failed to generate webhook URL', e, stackTrace);
      throw GenerateWebhookUrlException(e.toString());
    }
  }

  /// Gets the platform identifier string (ios, android).
  ///
  /// Caches the result to avoid unnecessary platform checks.
  Future<String> _getPlatform() async {
    // Return cached platform string if available
    if (_platformString != null) {
      return _platformString!;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _platformString = 'ios';
      return _platformString!;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      _platformString = 'android';
      return _platformString!;
    }

    _logger.severe('Unsupported platform: $defaultTargetPlatform');
    throw GenerateWebhookUrlException('Platform not supported');
  }

  /// Gets the notification token from the notification client.
  ///
  /// Caches the token to avoid repeated requests and manages token
  /// refresh when the cache expires.
  Future<String> _getToken() async {
    // Return cached token if still valid
    if (_cachedToken != null && _tokenCacheTime != null) {
      final DateTime now = DateTime.now();
      if (now.difference(_tokenCacheTime!) < _tokenCacheDuration) {
        _logger.fine('Using cached notification token');
        return _cachedToken!;
      }
      _logger.fine('Cached token expired, refreshing');
    }

    final String? token = await executeWithRetry<String?>(
      () => _notificationsClient.getToken(),
      operationName: 'get notification token',
      maxRetries: _maxRetries,
      logger: _logger,
    );

    // Update permission status after token request
    _logger.fine('Updating permission status after token request');
    await _permissionsCubit.checkNotificationPermission();

    if (token != null) {
      // Update cache
      _cachedToken = token;
      _tokenCacheTime = DateTime.now();
      return token;
    }

    _logger.severe('Failed to get notification token after multiple attempts');
    throw GenerateWebhookUrlException('Failed to get notification token');
  }

  /// Clears any cached tokens to force a refresh on next operation.
  void clearCache() {
    _cachedToken = null;
    _tokenCacheTime = null;
  }
}
