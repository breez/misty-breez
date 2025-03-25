import 'package:breez_preferences/breez_preferences.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LnUrlRegistrationManager');
final RegExp _usernameRegex = RegExp(r'^([^@]+)');

/// Manages Lightning URL address registration workflows.
///
/// This service is responsible for coordinating all LNURL registration operations:
/// - New registrations (with automatic retries for username conflicts)
/// - Username updates for existing registrations
/// - Recovery of existing registrations
/// - Ownership transfer (re-registration after recovery)
///
/// It provides a single entry point [performRegistration] that handles all scenarios
/// based on the provided [RegistrationType].
class LnUrlRegistrationManager {
  static const int maxRetries = 3;
  static const Duration _retryBackoff = Duration(milliseconds: 500);

  final LnUrlPayService lnAddressService;
  final BreezPreferences breezPreferences;
  final WebhookRequestBuilder requestBuilder;
  final UsernameResolver usernameResolver;
  final WebhookService webhookService;

  // Cached preference values
  String? _cachedWebhookUrl;
  String? _cachedUsername;
  bool? _isWebhookRegistered;

  LnUrlRegistrationManager({
    required this.lnAddressService,
    required this.breezPreferences,
    required this.requestBuilder,
    required this.usernameResolver,
    required this.webhookService,
  });

  /// Initializes cache for frequently accessed preferences.
  Future<void> _initPreferencesCache() async {
    _cachedWebhookUrl = await breezPreferences.webhookUrl;
    _cachedUsername = await breezPreferences.lnAddressUsername;
    _isWebhookRegistered = await breezPreferences.isLnUrlWebhookRegistered;
  }

  /// Updates cached preferences and persists changes.
  Future<void> _updatePreferences({
    String? webhookUrl,
    String? username,
    bool? isRegistered,
  }) async {
    // Update cache and persist changes in batch
    final List<Future<void>> updates = <Future<void>>[];

    if (webhookUrl != null) {
      _cachedWebhookUrl = webhookUrl;
      updates.add(breezPreferences.setWebhookUrl(webhookUrl));
    }

    if (username != null) {
      _cachedUsername = username;
      updates.add(breezPreferences.setLnAddressUsername(username));
    }

    if (isRegistered != null && isRegistered) {
      _isWebhookRegistered = true;
      updates.add(breezPreferences.setLnUrlWebhookRegistered());
    }

    if (updates.isNotEmpty) {
      await Future.wait(updates);
    }
  }

  /// Orchestrates the registration process based on the registration type.
  Future<RegisterRecoverLnurlPayResponse> performRegistration({
    required String pubKey,
    required String webhookUrl,
    required String registrationType,
    String? baseUsername,
    String? recoveredLightningAddress,
  }) async {
    // Initialize preference cache for this operation
    await _initPreferencesCache();

    try {
      switch (registrationType) {
        case RegistrationType.recovery:
          return await _handleRecoveryRegistration(
            pubKey: pubKey,
            webhookUrl: webhookUrl,
            baseUsername: baseUsername,
          );
        case RegistrationType.ownershipTransfer:
          return await _handleOwnershipTransferRegistration(
            pubKey: pubKey,
            webhookUrl: webhookUrl,
            baseUsername: baseUsername,
            recoveredLightningAddress: recoveredLightningAddress,
          );
        case RegistrationType.update:
          return await _handleUpdateRegistration(
            pubKey: pubKey,
            webhookUrl: webhookUrl,
            baseUsername: baseUsername,
            recoveredLightningAddress: recoveredLightningAddress,
          );
        case RegistrationType.newRegistration:
        default:
          return await _handleNewRegistration(
            pubKey: pubKey,
            webhookUrl: webhookUrl,
            baseUsername: baseUsername,
            recoveredLightningAddress: recoveredLightningAddress,
          );
      }
    } catch (e) {
      _logger.severe('Registration failed. Type: $registrationType', e);
      rethrow;
    }
  }

  /// Sets up a webhook for the given public key.
  Future<String> setupWebhook(String pubKey) async {
    await _initPreferencesCache();
    _logger.info('Setting up webhook for pubKey: $pubKey');

    // First, generate the new webhook URL
    final String webhookUrl = await webhookService.generateWebhookUrl();

    // Then unregister any existing webhook
    await _unregisterExistingWebhookIfNeeded(pubKey: pubKey, newWebhookUrl: webhookUrl);

    // Finally register the new webhook and update preferences in parallel
    await Future.wait(<Future<void>>[
      webhookService.register(webhookUrl),
      _updatePreferences(webhookUrl: webhookUrl),
    ]);

    _logger.info('Successfully setup webhook');
    return webhookUrl;
  }

  /// Handles the recovery registration flow.
  Future<RegisterRecoverLnurlPayResponse> _handleRecoveryRegistration({
    required String pubKey,
    required String webhookUrl,
    String? baseUsername,
  }) async {
    try {
      final RegisterRecoverLnurlPayResponse response = await _recoverWebhook(
        pubKey: pubKey,
        webhookUrl: webhookUrl,
      );

      if (response.lightningAddress.isNotEmpty) {
        if (_logger.isLoggable(Level.INFO)) {
          _logger.info('Recovered LNURL Webhook successfully. Re-registering to transfer ownership.');
        }
        return await _handleOwnershipTransferRegistration(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          recoveredLightningAddress: response.lightningAddress,
          baseUsername: baseUsername,
        );
      }

      if (_logger.isLoggable(Level.INFO)) {
        _logger.info('Recovery did not return a Lightning Address. Falling back to new registration.');
      }
      return await _handleNewRegistration(
        pubKey: pubKey,
        webhookUrl: webhookUrl,
        baseUsername: baseUsername,
      );
    } catch (e) {
      // Only log and process specific exceptions we can handle
      if (e is WebhookNotFoundException) {
        if (_logger.isLoggable(Level.INFO)) {
          _logger.info('Failed to recover LNURL Webhook. Falling back to registration.');
        }
        return await _handleNewRegistration(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          baseUsername: baseUsername,
        );
      }
      // Re-throw other exceptions for handling at higher level
      rethrow;
    }
  }

  /// Handles the ownership transfer registration flow after successful recovery.
  Future<RegisterRecoverLnurlPayResponse> _handleOwnershipTransferRegistration({
    required String pubKey,
    required String webhookUrl,
    String? baseUsername,
    String? recoveredLightningAddress,
  }) async {
    if (_logger.isLoggable(Level.INFO)) {
      _logger.info('Processing ownership transfer registration');
    }

    final String? username = await usernameResolver.resolveUsername(
      isNewRegistration: false, // Ownership transfer preserves existing username
      recoveredLightningAddress: recoveredLightningAddress,
      baseUsername: baseUsername,
    );

    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Using username for ownership transfer: ${username ?? "null"}');
    }

    return await _attemptRegistration(
      pubKey: pubKey,
      webhookUrl: webhookUrl,
      username: username,
    );
  }

  /// Handles the update registration flow.
  Future<RegisterRecoverLnurlPayResponse> _handleUpdateRegistration({
    required String pubKey,
    required String webhookUrl,
    String? baseUsername,
    String? recoveredLightningAddress,
  }) async {
    // Use cached values if available
    final bool isLnUrlWebhookRegistered =
        _isWebhookRegistered ?? await breezPreferences.isLnUrlWebhookRegistered;

    // Pass cached username as baseUsername if no explicit baseUsername was provided
    final String? effectiveBaseUsername = baseUsername ?? _cachedUsername;

    if (!isLnUrlWebhookRegistered) {
      return await _handleNewRegistration(
        pubKey: pubKey,
        webhookUrl: webhookUrl,
        baseUsername: baseUsername,
      );
    }

    final String? username = await usernameResolver.resolveUsername(
      isNewRegistration: false,
      recoveredLightningAddress: recoveredLightningAddress,
      baseUsername: effectiveBaseUsername,
    );

    return await _attemptRegistration(
      pubKey: pubKey,
      webhookUrl: webhookUrl,
      username: username,
    );
  }

  /// Handles the new registration flow.
  Future<RegisterRecoverLnurlPayResponse> _handleNewRegistration({
    required String pubKey,
    required String webhookUrl,
    String? baseUsername,
    String? recoveredLightningAddress,
  }) async {
    final String? username = await usernameResolver.resolveUsername(
      isNewRegistration: true,
      recoveredLightningAddress: recoveredLightningAddress,
      baseUsername: baseUsername,
    );

    return await _registerWithRetries(
      pubKey: pubKey,
      webhookUrl: webhookUrl,
      username: username!,
    );
  }

  /// Unregisters an existing webhook if it exists and differs from the new webhook URL.
  Future<String?> _unregisterExistingWebhookIfNeeded({
    required String pubKey,
    String? newWebhookUrl,
  }) async {
    // Use cached webhook URL if available
    final String? existingWebhook = _cachedWebhookUrl ?? await breezPreferences.webhookUrl;

    if (existingWebhook != null && (newWebhookUrl == null || existingWebhook != newWebhookUrl)) {
      if (_logger.isLoggable(Level.INFO)) {
        _logger.info('Unregistering existing webhook: $existingWebhook');
      }

      try {
        await _unregisterWebhook(pubKey: pubKey, webhookUrl: existingWebhook);
        breezPreferences.removeWebhookUrl();
        _cachedWebhookUrl = null;

        if (_logger.isLoggable(Level.FINE)) {
          _logger.fine('Successfully unregistered existing webhook');
        }
        return existingWebhook;
      } catch (e) {
        // Log but don't rethrow - we want to continue even if unregister fails
        _logger.warning('Failed to unregister existing webhook: $existingWebhook', e);
        return null;
      }
    }
    return null;
  }

  /// Unregisters a webhook.
  Future<void> _unregisterWebhook({
    required String pubKey,
    required String webhookUrl,
  }) async {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine('Unregistering webhook: $webhookUrl');
    }

    final UnregisterRecoverLnurlPayRequest request = await requestBuilder.buildUnregisterRecoverRequest(
      webhookUrl: webhookUrl,
    );
    await lnAddressService.unregister(pubKey: pubKey, request: request);
  }

  /// Attempts to register a webhook with the given username.
  Future<RegisterRecoverLnurlPayResponse> _attemptRegistration({
    required String pubKey,
    required String webhookUrl,
    String? username,
  }) async {
    final RegisterLnurlPayRequest request = await requestBuilder.buildRegisterRequest(
      webhookUrl: webhookUrl,
      username: username,
    );

    if (_logger.isLoggable(Level.INFO)) {
      _logger.info('Attempting to register LNURL Webhook for pubKey: $pubKey');
    }

    final RegisterRecoverLnurlPayResponse response = await lnAddressService.register(
      pubKey: pubKey,
      request: request,
    );

    // Batch preference updates to minimize disk writes
    await _updatePreferences(
      username: username?.isNotEmpty == true ? username : null,
      isRegistered: true,
    );

    if (_logger.isLoggable(Level.INFO)) {
      _logger.info('Successfully registered LNURL Webhook');
    }

    return response;
  }

  /// Attempts to register a webhook with retries for username conflicts.
  Future<RegisterRecoverLnurlPayResponse> _registerWithRetries({
    required String pubKey,
    required String webhookUrl,
    required String username,
  }) async {
    final String baseUsername = username;

    // Pre-generate potential usernames to avoid regenerating on each retry
    final List<String> alternativeUsernames = <String>[];
    for (int i = 1; i < maxRetries; i++) {
      alternativeUsernames.add(UsernameGenerator.generateUsername(baseUsername, i));
    }

    // Initialize with the base username
    String currentUsername = username;
    Exception? lastException;

    for (int retryCount = 0; retryCount < maxRetries; retryCount++) {
      try {
        if (_logger.isLoggable(Level.INFO)) {
          _logger.info('Attempt ${retryCount + 1}/$maxRetries with username: $currentUsername');
        }

        // Attempt registration
        return await _attemptRegistration(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          username: currentUsername,
        );
      } on UsernameConflictException {
        if (_logger.isLoggable(Level.WARNING)) {
          _logger.warning('Username conflict for: $currentUsername.');
        }

        if (retryCount < maxRetries - 1) {
          // Use pre-generated username for next attempt
          currentUsername = alternativeUsernames[retryCount];

          // Apply exponential backoff
          final Duration backoffTime = _retryBackoff * (1 << retryCount);
          await Future<void>.delayed(backoffTime);
        } else {
          _logger.severe('Max retries exceeded for username registration');
          throw MaxRetriesExceededException();
        }
      } catch (e) {
        // For non-username errors, track the last exception
        _logger.severe('Failed to register LNURL Webhook on attempt ${retryCount + 1}.', e);
        lastException = e is Exception ? e : Exception(e.toString());

        if (retryCount == maxRetries - 1) {
          throw lastException;
        }

        // Apply exponential backoff
        final Duration backoffTime = _retryBackoff * (1 << retryCount);
        await Future<void>.delayed(backoffTime);
      }
    }

    // Fallback exception if somehow loop exits without returning or throwing
    throw lastException ?? MaxRetriesExceededException();
  }

  /// Attempts to recover an existing webhook.
  Future<RegisterRecoverLnurlPayResponse> _recoverWebhook({
    required String pubKey,
    required String webhookUrl,
  }) async {
    if (_logger.isLoggable(Level.INFO)) {
      _logger.info('Attempting to recover LNURL Webhook for pubKey: $pubKey');
    }

    final UnregisterRecoverLnurlPayRequest request = await requestBuilder.buildUnregisterRecoverRequest(
      webhookUrl: webhookUrl,
    );

    try {
      final RegisterRecoverLnurlPayResponse recoverResponse = await lnAddressService.recover(
        pubKey: pubKey,
        request: request,
      );

      final String lightningAddress = recoverResponse.lightningAddress;
      if (lightningAddress.isEmpty) {
        if (_logger.isLoggable(Level.WARNING)) {
          _logger.warning('Recover response has no Lightning Address. Will need fallback to registration.');
        }
        return recoverResponse;
      }

      // Use regexp for efficient username extraction
      final String username = _extractUsernameFromLightningAddress(lightningAddress);

      // Batch preference updates into one call
      if (username.isNotEmpty) {
        await _updatePreferences(
          username: username,
          isRegistered: true,
        );
      }

      if (_logger.isLoggable(Level.INFO)) {
        _logger.info('Successfully recovered LNURL Webhook');
      }

      return recoverResponse;
    } catch (e) {
      if (_logger.isLoggable(Level.SEVERE)) {
        _logger.severe('Failed to recover LNURL Webhook.', e);
      }
      rethrow;
    }
  }

  /// Extracts the username part from a lightning address using RegExp.
  String _extractUsernameFromLightningAddress(String lightningAddress) {
    if (lightningAddress.isEmpty) {
      return '';
    }

    final RegExpMatch? match = _usernameRegex.firstMatch(lightningAddress);
    return match != null ? match.group(1)! : '';
  }
}
