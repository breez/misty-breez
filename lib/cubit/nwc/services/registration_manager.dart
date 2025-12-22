import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/nwc/models/models.dart';
import 'package:misty_breez/cubit/nwc/services/services.dart';

final Logger _logger = Logger('NwcRegistrationManager');

class NwcRegistrationManager {
  NwcWebhookRequestBuilder requestBuilder;
  NwcWebhookService webhookService;

  NwcRegistrationManager({required this.requestBuilder, required this.webhookService});

  Future<String> setupWebhook(String appPubkey, List<String> relays) async {
    _logger.info('Setting up webhook for app: $appPubkey');

    // First, generate the new webhook URL
    final String webhookUrl = await webhookService.generateWebhookUrl();

    final RegisterNwcWebhookRequest req = await requestBuilder.buildRegisterRequest(
      webhookUrl: webhookUrl,
      appPubkey: appPubkey,
      relays: relays,
    );

    // Finally register the new webhook and update preferences in parallel
    await Future.wait(<Future<void>>[
      webhookService.register(req),
      // _updatePreferences(webhookUrl: webhookUrl),
    ]);

    _logger.info('Successfully setup webhook');
    return webhookUrl;
  }
}
