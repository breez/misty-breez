import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('WebhookRequestBuilder');

class WebhookRequestBuilder {
  final MessageSigner messageSigner;

  WebhookRequestBuilder(this.messageSigner);

  Future<RegisterLnurlPayRequest> buildRegisterRequest({
    required String webhookUrl,
    String? username,
  }) async {
    _logger.info('Building register request with username: $username');
    final int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String usernameComponent = username?.isNotEmpty == true ? '-$username' : '';
    final String message = '$time-$webhookUrl$usernameComponent';
    final String signature = await messageSigner.signMessage(message);

    return RegisterLnurlPayRequest(
      time: time,
      webhookUrl: webhookUrl,
      signature: signature,
      username: username,
    );
  }

  Future<UnregisterRecoverLnurlPayRequest> buildRecoverRequest({
    required String webhookUrl,
  }) async {
    _logger.info('Building recover/unregister request');
    final int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String message = '$time-$webhookUrl';
    final String signature = await messageSigner.signMessage(message);

    return UnregisterRecoverLnurlPayRequest(
      time: time,
      webhookUrl: webhookUrl,
      signature: signature,
    );
  }
}
