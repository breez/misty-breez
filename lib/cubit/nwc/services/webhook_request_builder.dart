import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/nwc/models/models.dart';
import 'package:misty_breez/utils/webhooks/webhooks.dart';

final Logger _logger = Logger('NwcWebhookRequestBuilder');

class NwcWebhookRequestBuilder {
  final MessageSigner messageSigner;

  NwcWebhookRequestBuilder(this.messageSigner);

  Future<RegisterNwcWebhookRequest> buildRegisterRequest({
    required String webhookUrl,
    required String walletServicePubkey,
    required String appPubkey,
    required List<String> relays,
  }) async {
    try {
      _logger.info('Building registration request for webhook: $webhookUrl');

      // Build the signed request
      final String signature = await _buildSignedRegisterRequest(
        webhookUrl: webhookUrl,
        walletServicePubkey: walletServicePubkey,
        appPubkey: appPubkey,
        relays: relays,
      );

      // Create and return the final request object
      final RegisterNwcWebhookRequest request = RegisterNwcWebhookRequest(
        webhookUrl: webhookUrl,
        walletServicePubkey: walletServicePubkey,
        appPubkey: appPubkey,
        relays: relays,
        signature: signature,
      );

      _logger.info('Successfully built registration request');
      return request;
    } catch (e, stackTrace) {
      _logger.severe('Failed to build registration request', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _buildSignedRegisterRequest({
    required String webhookUrl,
    required String walletServicePubkey,
    required String appPubkey,
    required List<String> relays,
  }) async {
    final String message = '$webhookUrl-$walletServicePubkey-$appPubkey-[${relays.join(' ')}]';
    _logger.fine('Signing message: $message');
    return await messageSigner.signMessage(message);
  }

  Future<UnregisterNwcWebhookRequest> buildUnregisterRequest({
    required String walletServicePubkey,
    required String appPubkey,
  }) async {
    try {
      _logger.info('Building unregister request');

      // Build the signed request data
      final SignedRequestData requestData = await _buildSignedUnregisterRequest(
        walletServicePubkey: walletServicePubkey,
        appPubkey: appPubkey,
      );

      // Create and return the final request object
      final UnregisterNwcWebhookRequest request = UnregisterNwcWebhookRequest(
        time: requestData.timestamp,
        walletServicePubkey: walletServicePubkey,
        appPubkey: appPubkey,
        signature: requestData.signature,
      );

      _logger.info('Successfully built unregister request with timestamp: ${requestData.timestamp}');
      return request;
    } catch (e, stackTrace) {
      _logger.severe('Failed to build unregister request', e, stackTrace);
      rethrow;
    }
  }

  Future<SignedRequestData> _buildSignedUnregisterRequest({
    required String walletServicePubkey,
    required String appPubkey,
  }) async {
    // Create a Unix timestamp (seconds since epoch)
    final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Build the message to sign
    final String message = '$timestamp-$walletServicePubkey-$appPubkey';
    _logger.fine('Signing message: $message');

    // Sign the message
    final String signature = await messageSigner.signMessage(message);
    return SignedRequestData(timestamp: timestamp, signature: signature);
  }
}
