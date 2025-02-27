import 'dart:async';

import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:flutter/foundation.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('WebhookService');

/// Service responsible for managing webhooks for Lightning Network payments.
///
/// Handles webhook registration with the Breez SDK and generation of
/// webhook URLs for receiving payment notifications.
class WebhookService {
  /// Maximum number of retry attempts for operations.
  static const int _maxRetries = 3;

  /// Default timeout for SDK operations.
  static const Duration _defaultTimeout = Duration(seconds: 20);

  /// Default cache duration for notification tokens.
  static const Duration _tokenCacheDuration = Duration(hours: 1);

  /// Base URL for the notification service.
  static const String _notifierServiceURL = 'https://notifier.breez.technology';

  final BreezSDKLiquid _breezSdkLiquid;
  final NotificationsClient _notificationsClient;

  /// Cached notification token to avoid repeated requests.
  String? _cachedToken;

  /// When the token was last cached.
  DateTime? _tokenCacheTime;

  /// Platform string (ios, android) for webhook URL generation.
  String? _platformString;

  /// Creates a new [WebhookService] instance.
  ///
  /// Requires [BreezSDKLiquid] for webhook registration and
  /// [NotificationsClient] for notification token management.
  WebhookService(this._breezSdkLiquid, this._notificationsClient);

  /// Registers a webhook with the Breez SDK.
  ///
  /// The [webhookUrl] is the URL that will receive payment notifications.
  /// Throws [RegisterWebhookException] if registration fails.
  Future<void> register(String webhookUrl, {Duration timeout = _defaultTimeout}) async {
    _logger.info('Registering webhook: $webhookUrl');

    await _executeWithRetry<void>(
      () => _registerWebhook(webhookUrl, timeout),
      operationName: 'register webhook',
    );

    _logger.info('Successfully registered webhook');
  }

  /// Generates a webhook URL for receiving payment notifications.
  ///
  /// The URL includes the device platform and notification token.
  /// Throws [GenerateWebhookUrlException] if URL generation fails.
  Future<String> generateWebhookUrl() async {
    _logger.info('Generating webhook URL');

    try {
      final List<String> components = await Future.wait(<Future<String>>[
        _getPlatform(),
        _getToken(),
      ]);

      final String platform = components[0];
      final String token = components[1];

      final String webhookUrl = '$_notifierServiceURL/api/v1/notify?platform=$platform&token=$token';
      _logger.info('Generated webhook URL: $webhookUrl');

      return webhookUrl;
    } catch (e, stackTrace) {
      _logger.severe('Failed to generate webhook URL', e, stackTrace);
      throw GenerateWebhookUrlException(e.toString());
    }
  }

  /// Registers a webhook with timeout handling.
  Future<void> _registerWebhook(String webhookUrl, Duration timeout) async {
    try {
      final BindingLiquidSdk? sdk = _breezSdkLiquid.instance;
      if (sdk == null) {
        throw RegisterWebhookException('Breez SDK not initialized');
      }

      await sdk.registerWebhook(webhookUrl: webhookUrl).timeout(
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

    final String? token = await _executeWithRetry<String?>(
      () => _notificationsClient.getToken(),
      operationName: 'get notification token',
    );

    if (token != null) {
      // Update cache
      _cachedToken = token;
      _tokenCacheTime = DateTime.now();
      return token;
    }

    _logger.severe('Failed to get notification token after multiple attempts');
    throw GenerateWebhookUrlException('Failed to get notification token');
  }

  /// Executes an operation with retry logic for transient errors.
  ///
  /// [operation] is the async operation to execute.
  /// [maxRetries] is the maximum number of retry attempts.
  /// [operationName] is used for logging.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    required String operationName,
    int maxRetries = _maxRetries,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts <= maxRetries) {
      try {
        return await operation();
      } on TimeoutException catch (e, stackTrace) {
        attempts++;
        lastException = e;

        if (attempts <= maxRetries) {
          final Duration backoff = Duration(milliseconds: 500 * (1 << attempts));
          _logger.warning(
            'Timeout occurred while trying to $operationName. '
            'Retrying in ${backoff.inMilliseconds}ms (attempt $attempts/$maxRetries)',
            e,
            stackTrace,
          );
          await Future<void>.delayed(backoff);
        } else {
          _logger.severe('Max retries exceeded for $operationName', e, stackTrace);
          rethrow;
        }
      } catch (e, stackTrace) {
        // Only retry specific errors that are likely transient
        if (_isTransientError(e)) {
          attempts++;
          lastException = e is Exception ? e : Exception(e.toString());

          if (attempts <= maxRetries) {
            final Duration backoff = Duration(milliseconds: 500 * (1 << attempts));
            _logger.warning(
              'Transient error occurred while trying to $operationName. '
              'Retrying in ${backoff.inMilliseconds}ms (attempt $attempts/$maxRetries)',
              e,
              stackTrace,
            );
            await Future<void>.delayed(backoff);
          } else {
            _logger.severe('Max retries exceeded for $operationName', e, stackTrace);
            throw lastException;
          }
        } else {
          // Non-transient errors should not be retried
          _logger.severe('Non-transient error occurred during $operationName', e, stackTrace);
          rethrow;
        }
      }
    }

    // This should never be reached unless something went wrong
    throw lastException ?? Exception('Failed to $operationName after multiple attempts');
  }

  /// Determines if an error is transient and can be retried.
  bool _isTransientError(dynamic error) {
    // Customize this logic based on specific error types in your application
    return error is TimeoutException ||
        error.toString().contains('network') ||
        error.toString().contains('connection') ||
        error.toString().contains('timeout');
  }

  /// Clears any cached tokens to force a refresh on next operation.
  void clearCache() {
    _cachedToken = null;
    _tokenCacheTime = null;
  }
}
