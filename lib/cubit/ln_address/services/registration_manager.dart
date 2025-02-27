import 'package:breez_preferences/breez_preferences.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LnUrlRegistrationManager');

class LnUrlRegistrationManager {
  static const int maxRetries = 3;

  final LnUrlPayService lnAddressService;
  final BreezPreferences breezPreferences;
  final WebhookRequestBuilder requestBuilder;
  final UsernameResolver usernameResolver;
  final WebhookService webhookService;

  LnUrlRegistrationManager({
    required this.lnAddressService,
    required this.breezPreferences,
    required this.requestBuilder,
    required this.usernameResolver,
    required this.webhookService,
  });

  Future<String> setupWebhook(String pubKey) async {
    _logger.info('Setting up webhook for pubKey: $pubKey');
    final String webhookUrl = await webhookService.generateWebhookUrl();
    await unregisterExistingWebhookIfNeeded(pubKey: pubKey, webhookUrl: webhookUrl);
    await webhookService.register(webhookUrl);
    await breezPreferences.setWebhookUrl(webhookUrl);
    _logger.info('Successfully setup webhook');
    return webhookUrl;
  }

  Future<void> unregisterExistingWebhookIfNeeded({required String pubKey, required String webhookUrl}) async {
    final String? existingWebhook = await breezPreferences.webhookUrl;
    if (existingWebhook != null && existingWebhook != webhookUrl) {
      _logger.info('Unregistering existing webhook: $existingWebhook');
      await unregisterWebhook(pubKey: pubKey, webhookUrl: existingWebhook);
      breezPreferences.removeWebhookUrl();
      _logger.info('Successfully unregistered existing webhook');
    }
  }

  Future<void> unregisterWebhook({
    required String pubKey,
    required String webhookUrl,
  }) async {
    _logger.info('Unregistering webhook: $webhookUrl');
    final UnregisterRecoverLnurlPayRequest request =
        await requestBuilder.buildRecoverRequest(webhookUrl: webhookUrl);
    await lnAddressService.unregister(pubKey: pubKey, request: request);
  }

  Future<RegisterRecoverLnurlPayResponse> registerWithRetries({
    required String pubKey,
    required String webhookUrl,
    required String username,
  }) async {
    final String baseUsername = username;
    for (int retryCount = 1; retryCount <= maxRetries; retryCount++) {
      try {
        _logger.info('Attempt $retryCount/$maxRetries with username: $username');
        return await attemptRegistration(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          username: username,
        );
      } on UsernameConflictException {
        _logger.warning('Username conflict for: $username.');
        username = UsernameGenerator.generateUsername(baseUsername, retryCount);
      } catch (e) {
        _logger.severe('Failed to register LNURL Webhook on attempt $retryCount.', e);
        if (retryCount == maxRetries) {
          rethrow;
        }
      }
    }

    _logger.severe('Max retries exceeded for username registration');
    throw MaxRetriesExceededException();
  }

  Future<RegisterRecoverLnurlPayResponse> attemptRegistration({
    required String pubKey,
    required String webhookUrl,
    String? username,
  }) async {
    final RegisterLnurlPayRequest request =
        await requestBuilder.buildRegisterRequest(webhookUrl: webhookUrl, username: username);

    _logger.info('Attempting to register LNURL Webhook for pubKey: $pubKey');
    final RegisterRecoverLnurlPayResponse response = await lnAddressService.register(
      pubKey: pubKey,
      request: request,
    );

    if (username != null && username.isNotEmpty) {
      await breezPreferences.setLnAddressUsername(username);
    }

    _logger.info('Successfully registered LNURL Webhook');
    await breezPreferences.setLnUrlWebhookRegistered();
    return response;
  }

  Future<RegisterRecoverLnurlPayResponse> recoverWebhook({
    required String pubKey,
    required String webhookUrl,
  }) async {
    _logger.info('Attempting to recover LNURL Webhook for pubKey: $pubKey');
    final UnregisterRecoverLnurlPayRequest request =
        await requestBuilder.buildRecoverRequest(webhookUrl: webhookUrl);

    try {
      final RegisterRecoverLnurlPayResponse recoverResponse = await lnAddressService.recover(
        pubKey: pubKey,
        request: request,
      );

      final String lightningAddress = recoverResponse.lightningAddress;
      if (lightningAddress.isEmpty) {
        _logger.warning('Recover response has no Lightning Address. Will need fallback to registration.');
        return recoverResponse;
      }

      final String username = lightningAddress.split('@').first;
      if (username.isNotEmpty) {
        await breezPreferences.setLnAddressUsername(username);
      }

      _logger.info('Successfully recovered LNURL Webhook');
      await breezPreferences.setLnUrlWebhookRegistered();
      return recoverResponse;
    } catch (e) {
      _logger.severe('Failed to recover LNURL Webhook.', e);
      rethrow;
    }
  }

  // The main orchestrator for all registration operations
  Future<RegisterRecoverLnurlPayResponse> performRegistration({
    required String pubKey,
    required String webhookUrl,
    required String registrationType,
    String? baseUsername,
    String? recoveredLightningAddress,
  }) async {
    switch (registrationType) {
      case RegistrationType.recovery:
        try {
          final RegisterRecoverLnurlPayResponse response =
              await recoverWebhook(pubKey: pubKey, webhookUrl: webhookUrl);

          // If we recovered successfully, we need to re-register to transfer ownership
          if (response.lightningAddress.isNotEmpty) {
            _logger.info('Recovered LNURL Webhook successfully. Re-registering to transfer ownership.');
            return await performRegistration(
              pubKey: pubKey,
              webhookUrl: webhookUrl,
              registrationType: RegistrationType.ownershipTransfer,
              recoveredLightningAddress: response.lightningAddress,
            );
          }

          // If recovery didn't have a lightning address, fall back to new registration
          _logger.info('Recovery did not return a Lightning Address. Falling back to new registration.');
          return await performRegistration(
            pubKey: pubKey,
            webhookUrl: webhookUrl,
            registrationType: RegistrationType.newRegistration,
            baseUsername: baseUsername,
          );
        } on WebhookNotFoundException {
          // Fallback to register a new webhook if recovery fails
          _logger.info('Failed to recover LNURL Webhook. Falling back to registration.');
          return await performRegistration(
            pubKey: pubKey,
            webhookUrl: webhookUrl,
            registrationType: RegistrationType.newRegistration,
            baseUsername: baseUsername,
          );
        }

      /// Handles re-registration after successful recovery for device ownership transfer.
      /// Preserves the username from the recovered lightning address.
      case RegistrationType.ownershipTransfer:
        final String? username = await usernameResolver.resolveUsername(
          isNewRegistration: false, // Ownership transfer is not a new registration
          recoveredLightningAddress: recoveredLightningAddress,
          baseUsername: baseUsername,
        );
        return await attemptRegistration(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          username: username,
        );

      case RegistrationType.update:
        final bool isLnUrlWebhookRegistered = await breezPreferences.isLnUrlWebhookRegistered;
        if (!isLnUrlWebhookRegistered) {
          // If updating a username but no webhook exists, treat as new registration
          return await performRegistration(
            pubKey: pubKey,
            webhookUrl: webhookUrl,
            registrationType: RegistrationType.newRegistration,
            baseUsername: baseUsername,
          );
        }

        final String? username = await usernameResolver.resolveUsername(
          isNewRegistration: false,
          recoveredLightningAddress: recoveredLightningAddress,
          baseUsername: baseUsername,
        );
        return await attemptRegistration(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          username: username,
        );

      case RegistrationType.newRegistration:
      default:
        final String? username = await usernameResolver.resolveUsername(
          isNewRegistration: true,
          recoveredLightningAddress: recoveredLightningAddress,
          baseUsername: baseUsername,
        );

        return await registerWithRetries(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          username: username!,
        );
    }
  }
}
