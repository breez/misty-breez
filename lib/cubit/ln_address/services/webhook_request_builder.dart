import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

final Logger _logger = Logger('WebhookRequestBuilder');

/// Builds signed webhook requests for Lightning Network services.
///
/// This class is responsible for creating properly formatted and signed
/// webhook requests for LNURL-pay registration, recovery, and unregistration.
class WebhookRequestBuilder {
  /// Service used to sign messages with the node's private key
  final MessageSigner messageSigner;

  /// Creates a new WebhookRequestBuilder with the given message signer.
  ///
  /// @param messageSigner The service used to create cryptographic signatures
  WebhookRequestBuilder(this.messageSigner);

  /// Builds a request to register a webhook URL with an optional username.
  ///
  /// Creates a signed request that can be sent to an LNURL-pay service
  /// to register a Lightning Address or payment handler.
  ///
  /// @param webhookUrl The URL that will receive webhook notifications
  /// @param username Optional username for the Lightning Address
  /// @return A properly formatted and signed registration request
  /// @throws Exception if message signing fails
  Future<RegisterLnurlPayRequest> buildRegisterRequest({
    required String webhookUrl,
    String? username,
  }) async {
    try {
      _logger.info('Building registration request for webhook: $webhookUrl');

      // Format the username component if provided
      final String usernameComponent = _formatUsernameComponent(username);

      // Build the signed request
      final SignedRequestData requestData = await _buildSignedRequestData(
        webhookUrl: webhookUrl,
        additionalData: usernameComponent,
      );

      // Create and return the final request object
      final RegisterLnurlPayRequest request = RegisterLnurlPayRequest(
        time: requestData.timestamp,
        webhookUrl: webhookUrl,
        signature: requestData.signature,
        username: username,
      );

      _logger.info('Successfully built registration request with timestamp: ${requestData.timestamp}');
      return request;
    } catch (e, stackTrace) {
      _logger.severe('Failed to build registration request', e, stackTrace);
      rethrow;
    }
  }

  /// Builds a request to unregister or recover a webhook URL.
  ///
  /// Creates a signed request that can be sent to an LNURL-pay service
  /// to unregister or recover a Lightning Address or payment handler.
  ///
  /// @param webhookUrl The URL to unregister or recover
  /// @return A properly formatted and signed unregister/recover request
  /// @throws Exception if message signing fails
  Future<UnregisterRecoverLnurlPayRequest> buildUnregisterRecoverRequest({
    required String webhookUrl,
  }) async {
    try {
      _logger.info('Building unregister/recover request for webhook: $webhookUrl');

      // Build the signed request data
      final SignedRequestData requestData = await _buildSignedRequestData(
        webhookUrl: webhookUrl,
      );

      // Create and return the final request object
      final UnregisterRecoverLnurlPayRequest request = UnregisterRecoverLnurlPayRequest(
        time: requestData.timestamp,
        webhookUrl: webhookUrl,
        signature: requestData.signature,
      );

      _logger.info('Successfully built unregister/recover request with timestamp: ${requestData.timestamp}');
      return request;
    } catch (e, stackTrace) {
      _logger.severe('Failed to build unregister/recover request', e, stackTrace);
      rethrow;
    }
  }

  /// Formats the username component for inclusion in the signed message.
  ///
  /// @param username The optional username to format
  /// @return A formatted string with a leading hyphen if username exists, empty string otherwise
  String _formatUsernameComponent(String? username) {
    if (username == null || username.isEmpty) {
      return '';
    }
    return '-$username';
  }

  /// Builds the common signed request data used by all request types.
  ///
  /// @param webhookUrl The webhook URL to include in the signed message
  /// @param additionalData Optional additional data to append to the message
  /// @return A data object containing the timestamp and signature
  /// @throws Exception if message signing fails
  Future<SignedRequestData> _buildSignedRequestData({
    required String webhookUrl,
    String additionalData = '',
  }) async {
    // Create a Unix timestamp (seconds since epoch)
    final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Build the message to sign
    final String message = '$timestamp-$webhookUrl$additionalData';
    _logger.fine('Signing message: $message');

    // Sign the message
    final String signature = await messageSigner.signMessage(message);

    return SignedRequestData(
      timestamp: timestamp,
      signature: signature,
    );
  }
}
