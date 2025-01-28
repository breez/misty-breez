import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LnAddressService');

class LnUrlPayService {
  static const int _maxRetries = 3;
  final String baseUrl;
  final http.Client _client;

  LnUrlPayService({
    this.baseUrl = 'https://breez.fun',
    http.Client? client,
  }) : _client = client ?? http.Client();

  // TODO(erdemyerebasmaz): Handle multiple device setup case
  Future<RegisterLnurlPayResponse> register({
    required String pubKey,
    required RegisterLnurlPayRequest request,
  }) async {
    _logger.info('Attempting to register lightning address for pubkey: $pubKey');
    final String baseUsername = request.username ?? '';

    // If this is an update (username is provided), don't retry
    if (request.username != null && request.username!.isNotEmpty) {
      return _attemptRegistration(
        pubKey: pubKey,
        request: request,
      );
    }

    // Retry only on initial setup
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      final String currentUsername = UsernameGenerator.generateUsername(baseUsername, retryCount);

      try {
        _logger.info('Attempt ${retryCount + 1}/$_maxRetries with username: $currentUsername');
        final RegisterLnurlPayResponse registrationResponse = await _attemptRegistration(
          pubKey: pubKey,
          request: request.copyWith(username: currentUsername),
        );
        _logger.info('Successfully registered lightning address: ${registrationResponse.lightningAddress}');
        return registrationResponse;
      } on UsernameConflictException {
        _logger.warning('Username conflict for: $currentUsername');
        retryCount++;
        if (retryCount == _maxRetries) {
          _logger.severe('Max retries exceeded for username registration');
          throw MaxRetriesExceededException();
        }
      }
    }
    throw MaxRetriesExceededException();
  }

  Future<RegisterLnurlPayResponse> _attemptRegistration({
    required String pubKey,
    required RegisterLnurlPayRequest request,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/lnurlpay/$pubKey');
    _logger.fine('Attempting registration at: $uri');

    try {
      final http.Response response = await _client.post(
        uri,
        body: jsonEncode(request.toJson()),
      );

      _logger.fine('Registration response status: ${response.statusCode}');
      _logger.fine('Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        return RegisterLnurlPayResponse.fromJson(
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

      _logger.severe('Registration attempt failed', e, stackTrace);
      throw RegisterLnurlPayException(e.toString());
    }
  }

  Future<void> unregister(String pubKey, UnregisterLnurlPayRequest request) async {
    _logger.info('Invalidating webhook: ${request.webhookUrl}');
    final Uri uri = Uri.parse('$baseUrl/lnurlpay/$pubKey');

    try {
      final http.Response response = await _client.delete(
        uri,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        throw UnregisterLnurlPayException(response.body);
      }
      _logger.info('Successfully invalidated webhook');
    } catch (e, stackTrace) {
      _logger.severe('Failed to invalidate webhook', e, stackTrace);
      throw UnregisterLnurlPayException(e.toString());
    }
  }
}
