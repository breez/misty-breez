import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

export 'ln_address_state.dart';
export 'models/models.dart';
export 'services/services.dart';
export 'utils/utils.dart';

final Logger _logger = Logger('LnAddressCubit');

class LnAddressCubitFactory {
  static LnAddressCubit create(ServiceInjector injector) {
    final BreezSDKLiquid breezSdkLiquid = injector.breezSdkLiquid;
    final BreezPreferences breezPreferences = injector.breezPreferences;

    final WebhookService webhookService = WebhookService(breezSdkLiquid, injector.notifications);

    return LnAddressCubit(
      breezSdkLiquid: breezSdkLiquid,
      breezPreferences: breezPreferences,
      lnAddressService: LnUrlPayService(),
      webhookService: webhookService,
    );
  }
}

class LnAddressCubit extends Cubit<LnAddressState> {
  static const int _maxRetries = 3;

  final BreezSDKLiquid breezSdkLiquid;
  final BreezPreferences breezPreferences;
  final LnUrlPayService lnAddressService;
  final WebhookService webhookService;

  LnAddressCubit({
    required this.breezSdkLiquid,
    required this.breezPreferences,
    required this.lnAddressService,
    required this.webhookService,
  }) : super(const LnAddressState()) {
    _initializeLnAddressCubit();
  }

  /// Attempts to recover the Lightning Address once pubKey is available
  void _initializeLnAddressCubit() {
    _logger.info('Initializing Lightning Address Cubit.');

    breezSdkLiquid.getInfoResponseStream.first.then(
      (GetInfoResponse getInfoResponse) {
        _logger.info('Received wallet info, setting up Lightning Address.');
        setupLightningAddress(pubKey: getInfoResponse.walletInfo.pubkey, isRecover: true);
      },
    ).catchError((Object e) {
      _logger.severe('Failed to initialize Lightning Address Cubit', e);
    });
  }

  /// Sets up or updates the Lightning Address.
  ///
  /// - If [isRecover] is true, it attempts to recover the LNURL Webhook. Fallbacks to registration on failure.
  /// - If [baseUsername] is provided, the function updates the Lightning Address username.
  /// - Otherwise, it initializes a new Lightning Address or refreshes an existing one.
  Future<void> setupLightningAddress({
    String? pubKey,
    bool isRecover = false,
    String? baseUsername,
  }) async {
    final bool isUpdating = baseUsername != null;
    final String actionMessage = isRecover
        ? 'Recovering Lightning Address'
        : isUpdating
            ? 'Update LN Address Username to: $baseUsername'
            : 'Setup Lightning Address';
    _logger.info(actionMessage);

    emit(
      state.copyWith(
        status: isUpdating ? state.status : LnAddressStatus.loading,
        updateStatus: isUpdating ? const LnAddressUpdateStatus(status: UpdateStatus.loading) : null,
      ),
    );

    try {
      final RegisterRecoverLnurlPayResponse registrationResponse = await _setupAndRegisterLnAddress(
        pubKey: pubKey,
        isRecover: isRecover,
        baseUsername: baseUsername,
      );

      emit(
        state.copyWith(
          status: LnAddressStatus.success,
          lnurl: registrationResponse.lnurl,
          lnAddress: registrationResponse.lightningAddress,
          updateStatus: isUpdating ? const LnAddressUpdateStatus(status: UpdateStatus.success) : null,
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to $actionMessage', e, stackTrace);
      final LnAddressStatus status = isUpdating ? state.status : LnAddressStatus.error;
      final Object? error = isUpdating ? null : e;
      final LnAddressUpdateStatus? updateStatus =
          isUpdating ? _createErrorUpdateStatus(e, actionMessage) : null;
      emit(
        state.copyWith(
          status: status,
          error: error,
          updateStatus: updateStatus,
        ),
      );
    }
  }

  LnAddressUpdateStatus _createErrorUpdateStatus(Object e, String action) {
    final String errorMessage = e is RegisterLnurlPayException
        ? (e.responseBody?.isNotEmpty == true ? e.responseBody! : e.message)
        : e is UsernameConflictException
            ? e.toString()
            : 'Failed to $action';

    return LnAddressUpdateStatus(
      status: UpdateStatus.error,
      error: e,
      errorMessage: errorMessage,
    );
  }

  /// Registers or updates an LNURL Webhook for a Lightning Address.
  ///
  /// - If [isRecover] is true, it attempts to recover the LNURL Webhook. Fallbacks to registration on failure.
  /// - If [baseUsername] is provided, it updates the existing registration.
  /// - Otherwise, it determines a suitable username and registers a new webhook.
  Future<RegisterRecoverLnurlPayResponse> _setupAndRegisterLnAddress({
    String? pubKey,
    bool isRecover = false,
    String? baseUsername,
  }) async {
    pubKey = pubKey ?? await _pubKey;
    final String webhookUrl = await _setupWebhook(pubKey);
    if (isRecover) {
      // Recover webhook
      try {
        return await _prepareAndRecoverLnurlWebhook(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
        );
      } on WebhookNotFoundException {
        // Fallback to register a new webhook if recovery fails
        _logger.info('Failed to recover LNURL Webhook. Falling back to registration.');
        return await _prepareAndRegisterLnurlWebhook(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          baseUsername: baseUsername,
        );
      }
    } else {
      // Registers a new webhook
      return await _prepareAndRegisterLnurlWebhook(
        pubKey: pubKey,
        webhookUrl: webhookUrl,
        baseUsername: baseUsername,
      );
    }
  }

  Future<String> get _pubKey async => (await _walletInfo).pubkey;

  Future<WalletInfo> get _walletInfo async =>
      (await breezSdkLiquid.instance?.getInfo())?.walletInfo ??
      (throw Exception('Failed to retrieve wallet info'));

  /// Sets up a webhook for the given public key.
  /// - Generates a new webhook URL, unregisters any existing webhook if needed,
  /// - Registers the new webhook, and stores the webhook URL in preferences.
  Future<String> _setupWebhook(String pubKey) async {
    _logger.info('Setting up webhook for pubKey: $pubKey');
    final String webhookUrl = await webhookService.generateWebhookUrl();
    await _unregisterExistingWebhookIfNeeded(pubKey: pubKey, webhookUrl: webhookUrl);
    await webhookService.register(webhookUrl);
    await breezPreferences.setWebhookUrl(webhookUrl);
    _logger.info('Successfully setup webhook setup.');
    return webhookUrl;
  }

  /// Checks if there is an existing webhook URL and unregisters it if different from the provided one.
  Future<void> _unregisterExistingWebhookIfNeeded({
    required String pubKey,
    required String webhookUrl,
  }) async {
    final String? existingWebhook = await breezPreferences.webhookUrl;
    if (existingWebhook != null && existingWebhook != webhookUrl) {
      _logger.info('Unregistering existing webhook: $existingWebhook');
      await _unregisterWebhook(pubKey: pubKey, webhookUrl: existingWebhook);
      breezPreferences.removeWebhookUrl();
      _logger.info('Successfully registered existing webhook.');
    }
  }

  /// Unregisters a webhook for a given public key.
  Future<void> _unregisterWebhook({
    required String pubKey,
    required String webhookUrl,
  }) async {
    _logger.info('Prepared unregister LNURL Webhook request.');
    final int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final String message = '$time-$webhookUrl';
    final String signature = await _signMessage(message);

    final UnregisterRecoverLnurlPayRequest unregisterRequest = UnregisterRecoverLnurlPayRequest(
      time: time,
      webhookUrl: webhookUrl,
      signature: signature,
    );
    _logger.info('Prepared unregister LNURL Webhook request.');
    await lnAddressService.unregister(pubKey: pubKey, request: unregisterRequest);
  }

  /// Signs the given message with the private key.
  Future<String> _signMessage(String message) async {
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

  /// Resolves the appropriate username for LNURL registration.
  ///
  /// - If the webhook is not yet registered, it utilizes default profile name as username.
  /// - If the webhook is already registered, it retrieves the stored username from [BreezPreferences].
  Future<String?> _resolveUsername({required bool isNewRegistration}) async {
    if (isNewRegistration) {
      final String? profileName = await breezPreferences.profileName;
      final String formattedUsername = UsernameFormatter.formatDefaultProfileName(profileName);
      _logger.info('Registering LNURL Webhook: Using formatted profile name: $formattedUsername');
      return formattedUsername;
    }

    // TODO(erdemyerebasmaz): Add null-handling to revert to the profile name if the stored username is null.
    final String? storedUsername = await breezPreferences.lnAddressUsername;
    _logger.info('Refreshing LNURL Webhook: Using stored username: $storedUsername');
    return storedUsername;
  }

  /// Signs a webhook request message for authentication and validation purposes.
  Future<String> _generateWebhookSignature({
    required int time,
    required String webhookUrl,
    String? username,
  }) async {
    _logger.info('Generating webhook signature');
    final String usernameComponent = username?.isNotEmpty == true ? '-$username' : '';
    final String message = '$time-$webhookUrl$usernameComponent';
    final String signature = await _signMessage(message);
    _logger.info('Successfully generated webhook signature');
    return signature;
  }

  /// Prepares recover request & recovers a webhook for a given public key.
  Future<RegisterRecoverLnurlPayResponse> _prepareAndRecoverLnurlWebhook({
    required String pubKey,
    required String webhookUrl,
  }) async {
    _logger.info('Preparing recover LNURL Webhook request.');
    final int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final String message = '$time-$webhookUrl';
    final String signature = await _signMessage(message);

    final UnregisterRecoverLnurlPayRequest recoverRequest = UnregisterRecoverLnurlPayRequest(
      time: time,
      webhookUrl: webhookUrl,
      signature: signature,
    );

    _logger.info('Prepared recover LNURL Webhook request.');
    return await _recoverLnurlWebhook(pubKey: pubKey, request: recoverRequest);
  }

  /// Recovers an LNURL Webhook with the provided public key and request.
  ///
  ///  - Saves the username to [BreezPreferences] if present and
  ///  - Sets webhook as registered on [BreezPreferences] if succeeds
  Future<RegisterRecoverLnurlPayResponse> _recoverLnurlWebhook({
    required String pubKey,
    required UnregisterRecoverLnurlPayRequest request,
  }) async {
    _logger.info('Attempting to recover LNURL Webhook for pubKey: $pubKey');
    try {
      final RegisterRecoverLnurlPayResponse recoverResponse = await lnAddressService.recover(
        pubKey: pubKey,
        request: request,
      );

      final String username = recoverResponse.lightningAddress.split('@').first;
      if (username.isNotEmpty) {
        await breezPreferences.setLnAddressUsername(username);
      }

      _logger.info('Successfully recovered LNURL Webhook: $recoverResponse');

      await breezPreferences.setLnUrlWebhookRegistered();
      return recoverResponse;
    } catch (e) {
      _logger.severe('Failed to recover LNURL Webhook.', e);
      rethrow;
    }
  }

  /// Prepares register request & registers a webhook for a given public key.
  Future<RegisterRecoverLnurlPayResponse> _prepareAndRegisterLnurlWebhook({
    required String pubKey,
    required String webhookUrl,
    required String? baseUsername,
  }) async {
    _logger.info('Preparing register LNURL Webhook request.');
    final bool isUpdating = baseUsername != null;
    final bool isLnUrlWebhookRegistered = await breezPreferences.isLnUrlWebhookRegistered;
    final bool isNewRegistration = !(isUpdating && isLnUrlWebhookRegistered);

    final String? username = baseUsername ?? await _resolveUsername(isNewRegistration: isNewRegistration);

    // Register without retries if this is an update to existing LNURL Webhook
    if (!isNewRegistration) {
      return await _attemptRegisterLnurlWebhook(
        pubKey: pubKey,
        webhookUrl: webhookUrl,
        username: username,
      );
    }

    // Register with retries if LNURL Webhook hasn't been registered yet
    return await _registerWithRetries(
      pubKey: pubKey,
      webhookUrl: webhookUrl,
      username: username!,
    );
  }

  // TODO(erdemyerebasmaz): Optimize if current retry logic is insufficient
  // If initial registration fails, up to [_maxRetries] registration attempts will be made on opening [ReceiveLightningAddressPage].
  // If these attempts also fail, the user can retry manually via a button, which will trigger another registration attempt with [_maxRetries] retries.
  //
  // Future improvements could include:
  // - Retrying indefinitely with intervals until registration succeeds
  // - Explicit handling of [UsernameConflictException] and LNURL server connectivity issues
  // - Randomizing the default profile name itself after a set number of failures
  // - Adding additional digits to the discriminator
  Future<RegisterRecoverLnurlPayResponse> _registerWithRetries({
    required String pubKey,
    required String webhookUrl,
    required String username,
  }) async {
    final String baseUsername = username;
    for (int retryCount = 1; retryCount <= _maxRetries; retryCount++) {
      try {
        _logger.info('Attempt $retryCount/$_maxRetries with username: $username');
        return await _attemptRegisterLnurlWebhook(
          pubKey: pubKey,
          webhookUrl: webhookUrl,
          username: username,
        );
      } on UsernameConflictException {
        _logger.warning('Username conflict for: $username.');
        username = UsernameGenerator.generateUsername(baseUsername, retryCount);
      } catch (e) {
        _logger.severe('Failed to register LNURL Webhook on attempt ${retryCount + 1}.', e);
        if (retryCount == _maxRetries - 1) {
          _logger.severe('Max retries exceeded for username registration');
          throw MaxRetriesExceededException();
        }
        rethrow;
      }
    }

    throw RegisterLnurlPayException('Failed to register LNURL Webhook.');
  }

  Future<RegisterRecoverLnurlPayResponse> _attemptRegisterLnurlWebhook({
    required String pubKey,
    required String webhookUrl,
    String? username,
  }) async {
    _logger.info('Prepared register LNURL Webhook request.');
    final RegisterLnurlPayRequest request = await _prepareRegisterLnurlPayRequest(
      pubKey: pubKey,
      webhookUrl: webhookUrl,
      username: username,
    );
    _logger.info('Prepared register LNURL Webhook request.');
    return await _registerLnurlWebhook(
      pubKey: pubKey,
      request: request,
    );
  }

  /// Attempts to register LNURL Webhook once with the given parameters.
  Future<RegisterLnurlPayRequest> _prepareRegisterLnurlPayRequest({
    required String pubKey,
    required String webhookUrl,
    required String? username,
  }) async {
    final int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String signature = await _generateWebhookSignature(
      time: time,
      webhookUrl: webhookUrl,
      username: username,
    );

    return RegisterLnurlPayRequest(
      time: time,
      webhookUrl: webhookUrl,
      signature: signature,
      username: username,
    );
  }

  /// Registers an LNURL Webhook with the provided public key and request.
  ///
  ///  - Saves the username to [BreezPreferences] if present and
  ///  - Sets webhook as registered on [BreezPreferences] if succeeds
  Future<RegisterRecoverLnurlPayResponse> _registerLnurlWebhook({
    required String pubKey,
    required RegisterLnurlPayRequest request,
  }) async {
    _logger.info('Attempting to register LNURL Webhook for pubKey: $pubKey');
    try {
      final RegisterRecoverLnurlPayResponse registrationResponse = await lnAddressService.register(
        pubKey: pubKey,
        request: request,
      );

      final String? username = request.username;
      if (username != null && username.isNotEmpty) {
        await breezPreferences.setLnAddressUsername(username);
      }

      _logger.info('Successfully registered LNURL Webhook: $registrationResponse');

      await breezPreferences.setLnUrlWebhookRegistered();
      return registrationResponse;
    } catch (e) {
      _logger.severe('Failed to register LNURL Webhook.', e);
      rethrow;
    }
  }

  void clearUpdateStatus() {
    _logger.info('Clearing LnAddressUpdateStatus');
    emit(
      state.copyWith(
        updateStatus: const LnAddressUpdateStatus(),
      ),
    );
  }
}
