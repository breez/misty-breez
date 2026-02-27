import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/nwc/models/models.dart';
import 'package:misty_breez/cubit/nwc/services/services.dart';

final Logger _logger = Logger('NwcRegistrationManager');

class NwcRegistrationManager {
  NwcWebhookRequestBuilder requestBuilder;
  NwcWebhookService webhookService;

  NwcRegistrationManager({required this.requestBuilder, required this.webhookService});

  Future<String> setupWebhook(
    String walletPubkey,
    String walletServicePubkey,
    String appPubkey,
    List<String> relays,
  ) async {
    _logger.info('Setting up webhook for app: $appPubkey');

    // First, generate the new webhook URL
    final String webhookUrl = await webhookService.generateWebhookUrl();

    final RegisterNwcWebhookRequest req = await requestBuilder.buildRegisterRequest(
      webhookUrl: webhookUrl,
      walletServicePubkey: walletServicePubkey,
      appPubkey: appPubkey,
      relays: relays,
    );

    await webhookService.register(walletPubkey, req);

    _logger.info('Successfully setup webhook');
    return webhookUrl;
  }

  Future<void> removeWebhook(String walletPubkey, String walletServicePubkey, String appPubkey) async {
    _logger.info('Removing webhook for app: $appPubkey');

    final UnregisterNwcWebhookRequest req = await requestBuilder.buildUnregisterRequest(
      walletServicePubkey: walletServicePubkey,
      appPubkey: appPubkey,
    );

    await webhookService.unregister(walletPubkey, req);

    _logger.info('Successfully removed webhook');
  }
}
