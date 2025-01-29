import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LnUrlPayService');

class LnUrlPayService {
  static const int _maxRetries = 3;
  static const String _baseUrl = 'https://breez.fun';
  static final http.Client _client = http.Client();

  // TODO(erdemyerebasmaz): Handle multiple device setup case
  Future<RegisterRecoverLnurlPayResponse> register({
    required String pubKey,
    required RegisterLnurlPayRequest request,
  }) async {
    _logger.info('Registering lightning address for pubkey: $pubKey with request: $request');

    // Register without retries if this is an update to existing LNURL Webhook
    if (request.username?.isNotEmpty ?? false) {
      return _register(pubKey: pubKey, request: request);
    }

    // Register with retries if LNURL Webhook hasn't been registered yet
    return _registerWithRetries(pubKey: pubKey, username: request.username ?? '', request: request);
  }

  // TODO(erdemyerebasmaz): Optimize if current retry logic is insufficient
  // If initial registration fails, up to [_maxRetries] registration attempts will be made on opening [ReceiveLightningAddressPage].
  // If these attempts also fail, the user can retry manually via a button, which will trigger another registration attempt with [_maxRetries] retries.
  //
  // Future improvements could include:
  // - Retrying indefinitely with intervals until registration succeeds
  // - Explicit handling of [UsernameConflictException] and LNURL server connectivity issues
  // - Randomizing the default profile name itself after a set number of failures
  // - Adding additional digits to the discriminator
  Future<RegisterRecoverLnurlPayResponse> _registerWithRetries({
    required String pubKey,
    required String username,
    required RegisterLnurlPayRequest request,
  }) async {
    for (int retryCount = 0; retryCount < _maxRetries; retryCount++) {
      final String currentUsername = UsernameGenerator.generateUsername(username, retryCount);
      try {
        _logger.info('Attempt ${retryCount + 1}/$_maxRetries with username: $currentUsername');
        return await _register(
          pubKey: pubKey,
          request: request.copyWith(username: currentUsername),
        );
      } on UsernameConflictException {
        _logger.warning('Username conflict for: $currentUsername');
      }
    }

    _logger.severe('Max retries exceeded for username registration');
    throw MaxRetriesExceededException();
  }

  Future<RegisterRecoverLnurlPayResponse> recover({
    required String pubKey,
    required UnregisterRecoverLnurlPayRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/lnurlpay/$pubKey/recover');
    _logger.fine('Sending recover request to: $uri');

    try {
      final http.Response response = await _client.post(
        uri,
        body: jsonEncode(request.toJson()),
      );
      _logHttpResponse(response);

      if (response.statusCode == 200) {
        return RegisterRecoverLnurlPayResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw RecoverLnurlPayException(
        'Server returned error response',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e, stackTrace) {
      if (e is RecoverLnurlPayException) {
        rethrow;
      }

      _logger.severe('Recovery failed', e, stackTrace);
      throw RecoverLnurlPayException(e.toString());
    }
  }

  Future<RegisterRecoverLnurlPayResponse> _register({
    required String pubKey,
    required RegisterLnurlPayRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/lnurlpay/$pubKey');
    _logger.fine('Sending registration request to: $uri');

    try {
      final http.Response response = await _client.post(
        uri,
        body: jsonEncode(request.toJson()),
      );
      _logHttpResponse(response);

      if (response.statusCode == 200) {
        return RegisterRecoverLnurlPayResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 409) {
        throw UsernameConflictException();
      }

      throw RegisterLnurlPayException(
        'Server returned error response',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e, stackTrace) {
      if (e is UsernameConflictException || e is RegisterLnurlPayException) {
        rethrow;
      }

      _logger.severe('Registration failed', e, stackTrace);
      throw RegisterLnurlPayException(e.toString());
    }
  }

  Future<void> unregister(String pubKey, UnregisterRecoverLnurlPayRequest request) async {
    _logger.info('Unregistering webhook: ${request.webhookUrl}');
    final Uri uri = Uri.parse('$_baseUrl/lnurlpay/$pubKey');

    try {
      final http.Response response = await _client.delete(
        uri,
        body: jsonEncode(request.toJson()),
      );
      _logHttpResponse(response);

      if (response.statusCode != 200) {
        throw UnregisterLnurlPayException(response.body);
      }

      _logger.info('Successfully unregistered webhook');
    } catch (e, stackTrace) {
      _logger.severe('Failed to unregister webhook', e, stackTrace);
      throw UnregisterLnurlPayException(e.toString());
    }
  }

  void _logHttpResponse(http.Response response) {
    _logger.fine('Response status: ${response.statusCode}');
    _logger.fine('Response body: ${response.body}');
  }
}
