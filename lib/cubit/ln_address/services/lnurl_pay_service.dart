import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:misty_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LnUrlPayService');

/// Service responsible for Lightning URL payment operations.
///
/// Handles registration, recovery, and unregistration of LNURL webhooks
/// by communicating with the Breez server.
class LnUrlPayService {
  static const int _maxRetries = 2;
  static const Duration _defaultTimeout = Duration(seconds: 30);

  static const String _baseUrl = 'https://breez.fun';
  static const String _lnurlPayEndpoint = '/lnurlpay';

  final http.Client _client;

  /// Creates a new [LnUrlPayService] with an optional HTTP client.
  ///
  /// If no client is provided, a new one will be created.
  LnUrlPayService({http.Client? client}) : _client = client ?? http.Client();

  /// Closes the HTTP client when the service is no longer needed.
  void dispose() {
    _client.close();
  }

  /// Registers a new LNURL webhook for the specified public key.
  ///
  /// Returns a [RegisterRecoverLnurlPayResponse] on success.
  /// Throws [UsernameConflictException] if the username is already taken.
  /// Throws [RegisterLnurlPayException] for other registration failures.
  Future<RegisterRecoverLnurlPayResponse> register({
    required String pubKey,
    required RegisterLnurlPayRequest request,
    Duration timeout = _defaultTimeout,
  }) async {
    _logger.info('Registering lightning address for pubkey: $pubKey');
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Registration request details: $request');
    }

    final Uri uri = _buildUri('$_lnurlPayEndpoint/$pubKey');

    return _executeWithRetry(
      () => _post(uri, request.toJson()),
      timeout: timeout,
      successHandler: (Map<String, dynamic> response) {
        return RegisterRecoverLnurlPayResponse.fromJson(response);
      },
      errorHandler: (int statusCode, String body) {
        if (statusCode == 409) {
          throw UsernameConflictException();
        }
        _logger.severe('Failed to register webhook.');
        throw RegisterLnurlPayException(
          'Server returned error response',
          statusCode: statusCode,
          responseBody: body,
        );
      },
      operationName: 'register webhook',
    );
  }

  /// Recovers an existing LNURL webhook for the specified public key.
  ///
  /// Returns a [RegisterRecoverLnurlPayResponse] on success.
  /// Throws [WebhookNotFoundException] if the webhook doesn't exist.
  /// Throws [RecoverLnurlPayException] for other recovery failures.
  Future<RegisterRecoverLnurlPayResponse> recover({
    required String pubKey,
    required UnregisterRecoverLnurlPayRequest request,
    Duration timeout = _defaultTimeout,
  }) async {
    _logger.info('Recovering webhook for pubkey: $pubKey');
    final Uri uri = _buildUri('$_lnurlPayEndpoint/$pubKey/recover');

    return _executeWithRetry(
      () => _post(uri, request.toJson()),
      timeout: timeout,
      successHandler: (Map<String, dynamic> response) {
        return RegisterRecoverLnurlPayResponse.fromJson(response);
      },
      errorHandler: (int statusCode, String body) {
        if (statusCode == 404) {
          throw WebhookNotFoundException();
        }
        _logger.severe('Failed to recover webhook.');
        throw RecoverLnurlPayException(
          'Server returned error response',
          statusCode: statusCode,
          responseBody: body,
        );
      },
      operationName: 'recover webhook',
    );
  }

  /// Unregisters an existing LNURL webhook for the specified public key.
  ///
  /// Throws [UnregisterLnurlPayException] if unregistration fails.
  Future<void> unregister({
    required String pubKey,
    required UnregisterRecoverLnurlPayRequest request,
    Duration timeout = _defaultTimeout,
  }) async {
    _logger.info('Unregistering webhook: ${request.webhookUrl}');
    final Uri uri = _buildUri('$_lnurlPayEndpoint/$pubKey');

    await _executeWithRetry<void>(
      () => _delete(uri, request.toJson()),
      timeout: timeout,
      successHandler: (_) {},
      errorHandler: (int statusCode, String body) {
        _logger.severe('Failed to unregister webhook.');
        throw UnregisterLnurlPayException(body);
      },
      operationName: 'unregister webhook',
    );

    _logger.info('Successfully unregistered webhook.');
  }

  /// Builds a URI for the specified endpoint.
  Uri _buildUri(String endpoint) {
    return Uri.parse('$_baseUrl$endpoint');
  }

  /// Executes a POST request with the given URI and body.
  Future<dynamic> _post(Uri uri, Map<String, dynamic> body, {Duration? timeout}) async {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Sending POST request to: $uri');
    }

    final Map<String, String> headers = <String, String>{'Content-Type': 'application/json'};
    final http.Response response = await _client
        .post(
          uri,
          body: jsonEncode(body),
          headers: headers,
        )
        .timeout(timeout ?? _defaultTimeout);

    return _processResponse(response);
  }

  /// Executes a DELETE request with the given URI and body.
  Future<dynamic> _delete(Uri uri, Map<String, dynamic> body, {Duration? timeout}) async {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Sending DELETE request to: $uri');
    }

    final Map<String, String> headers = <String, String>{'Content-Type': 'application/json'};
    final http.Response response = await _client
        .delete(
          uri,
          body: jsonEncode(body),
          headers: headers,
        )
        .timeout(timeout ?? _defaultTimeout);

    return _processResponse(response);
  }

  /// Processes the HTTP response and returns the response body.
  dynamic _processResponse(http.Response response) {
    _logHttpResponse(response);

    if (response.statusCode == 200) {
      try {
        final dynamic decodedBody = jsonDecode(response.body);
        return decodedBody;
      } catch (e) {
        _logger.warning('Failed to decode response body: ${response.body}', e);
        throw FormatException('Invalid response format', response.body);
      }
    }

    return LnurlPayServiceResponseError(response.statusCode, response.body);
  }

  /// Logs the HTTP response details.
  void _logHttpResponse(http.Response response) {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Response status: ${response.statusCode}');
      _logger.fine('Response body: ${response.body}');
    }
  }

  /// Executes an operation with retry logic.
  ///
  /// [operation] is the async operation to execute
  /// [successHandler] processes the successful response
  /// [errorHandler] handles error responses
  /// [timeout] is the timeout for each attempt
  /// [operationName] is used for logging
  Future<T> _executeWithRetry<T>(
    Future<dynamic> Function() operation, {
    required T Function(Map<String, dynamic>) successHandler,
    required void Function(int statusCode, String body) errorHandler,
    Duration? timeout,
    String? operationName,
  }) async {
    int attempts = 0;

    while (attempts <= _maxRetries) {
      try {
        final dynamic result = await operation();

        if (result is LnurlPayServiceResponseError) {
          errorHandler(result.statusCode, result.body);
          // If errorHandler doesn't throw, we'll exit the loop
          break;
        }

        return successHandler(result as Map<String, dynamic>);
      } on TimeoutException {
        attempts++;
        if (attempts <= _maxRetries) {
          final Duration backoff = Duration(milliseconds: 500 * (1 << attempts));
          _logger.warning(
            'Timeout occurred while trying to $operationName. '
            'Retrying in ${backoff.inMilliseconds}ms (attempt $attempts/$_maxRetries)',
          );
          await Future<void>.delayed(backoff);
        } else {
          _logger.severe('Max retries exceeded for $operationName due to timeout');
          rethrow;
        }
      } catch (e) {
        // Don't retry for non-timeout errors
        _logger.severe('Failed to $operationName.', e);
        rethrow;
      }
    }

    // This should never be reached unless errorHandler doesn't throw
    throw Exception('Failed to $operationName after multiple attempts');
  }
}
