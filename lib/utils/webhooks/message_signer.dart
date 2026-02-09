import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('MessageSigner');

class MessageSigner {
  final BreezSDKLiquid breezSdkLiquid;

  MessageSigner(this.breezSdkLiquid);

  Future<String> signMessage(String message) async {
    _logger.info('Signing message: $message');

    final SignMessageResponse? signMessageRes = breezSdkLiquid.instance?.signMessage(
      req: SignMessageRequest(message: message),
    );

    if (signMessageRes == null) {
      _logger.severe('Failed to sign message.');
      throw Exception('Failed to sign message');
    }

    _logger.info('Successfully signed message');
    return signMessageRes.signature;
  }
}
