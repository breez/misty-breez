import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LnUrlPayService');

class LnUrlPayService {
  static const String _baseUrl = 'https://breez.fun';
  static final http.Client _client = http.Client();

  // TODO(erdemyerebasmaz): Handle multiple device setup case
  Future<RegisterRecoverLnurlPayResponse> register({
    required String pubKey,
    required RegisterLnurlPayRequest request,
  }) async {
    _logger.info('Registering lightning address for pubkey: $pubKey with request: $request');
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
      _logger.severe('Failed to register webhook.', e, stackTrace);
      rethrow;
    }
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

      if (response.statusCode == 404) {
        throw WebhookNotFoundException();
      }

      throw RecoverLnurlPayException(
        'Server returned error response',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to recover webhook.', e, stackTrace);
      rethrow;
    }
  }

  Future<void> unregister({
    required String pubKey,
    required UnregisterRecoverLnurlPayRequest request,
  }) async {
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

      _logger.info('Successfully unregistered webhook.');
    } catch (e, stackTrace) {
      _logger.severe('Failed to unregister webhook.', e, stackTrace);
      rethrow;
    }
  }

  void _logHttpResponse(http.Response response) {
    _logger.fine('Response status: ${response.statusCode}');
    _logger.fine('Response body: ${response.body}');
  }
}
