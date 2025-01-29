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
  final BreezSDKLiquid breezSdkLiquid;
  final BreezPreferences breezPreferences;
  final LnUrlPayService lnAddressService;
  final WebhookService webhookService;

  LnAddressCubit({
    required this.breezSdkLiquid,
    required this.breezPreferences,
    required this.lnAddressService,
    required this.webhookService,
  }) : super(const LnAddressState());

  /// Sets up or updates the Lightning Address.
  ///
  /// - If [baseUsername] is provided, the function updates the Lightning Address username.
  /// - Otherwise, it initializes a new Lightning Address or refreshes an existing one.
  Future<void> setupLightningAddress({String? baseUsername}) async {
    final bool isUpdating = baseUsername != null;
    final String actionMessage =
        isUpdating ? 'Update LN Address Username to: $baseUsername' : 'Setup Lightning Address';
    _logger.info(actionMessage);

    emit(
      state.copyWith(
        status: isUpdating ? state.status : LnAddressStatus.loading,
        updateStatus: isUpdating ? const LnAddressUpdateStatus(status: UpdateStatus.loading) : null,
      ),
    );

    try {
      final RegisterLnurlPayResponse registrationResponse = await _setupAndRegisterLnAddress(
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

  /// Registers or updates an LNURL webhook for a Lightning Address.
  ///
  /// - If [baseUsername] is provided, it updates the existing registration.
  /// - Otherwise, it determines a suitable username and registers a new webhook.
  Future<RegisterLnurlPayResponse> _setupAndRegisterLnAddress({String? baseUsername}) async {
    final WalletInfo walletInfo = await _getWalletInfo();
    final String webhookUrl = await _setupWebhook(walletInfo.pubkey);
    final String? username = baseUsername ?? await _resolveUsername();
    final int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String signature = await _generateWebhookSignature(time, webhookUrl, username);
    final RegisterLnurlPayRequest request = RegisterLnurlPayRequest(
      time: time,
      webhookUrl: webhookUrl,
      signature: signature,
      username: username,
    );
    return await _registerLnurlWebhook(
      pubKey: walletInfo.pubkey,
      request: request,
    );
  }

  Future<WalletInfo> _getWalletInfo() async {
    final WalletInfo? walletInfo = (await breezSdkLiquid.instance?.getInfo())?.walletInfo;
    if (walletInfo == null) {
      throw Exception('Failed to retrieve wallet info');
    }
    return walletInfo;
  }

  /// Sets up a webhook for the given public key.
  /// - Generates a new webhook URL, unregisters any existing webhook if needed,
  /// - Registers the new webhook, and stores the webhook URL in preferences.
  Future<String> _setupWebhook(String pubKey) async {
    _logger.info('Setting up webhook');
    final String webhookUrl = await webhookService.generateWebhookUrl();
    await _unregisterExistingWebhookIfNeeded(pubKey: pubKey, webhookUrl: webhookUrl);
    await webhookService.register(webhookUrl);
    await breezPreferences.setWebhookUrl(webhookUrl);
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
      await _unregisterWebhook(existingWebhook, pubKey);
      breezPreferences.removeWebhookUrl();
    }
  }

  /// Unregisters a webhook for a given public key.
  Future<void> _unregisterWebhook(String webhookUrl, String pubKey) async {
    final int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final String message = '$time-$webhookUrl';
    final String signature = await _signMessage(message);

    final UnregisterLnurlPayRequest invalidateWebhookRequest = UnregisterLnurlPayRequest(
      time: time,
      webhookUrl: webhookUrl,
      signature: signature,
    );

    await lnAddressService.unregister(pubKey, invalidateWebhookRequest);
  }

  /// Signs the given message with the private key.
  Future<String> _signMessage(String message) async {
    _logger.info('Signing message: $message');

    final SignMessageResponse? signMessageRes = breezSdkLiquid.instance?.signMessage(
      req: SignMessageRequest(message: message),
    );

    if (signMessageRes == null) {
      throw Exception('Failed to sign message');
    }

    _logger.info('Successfully signed message');
    return signMessageRes.signature;
  }

  /// Resolves the appropriate username for LNURL registration.
  ///
  /// - If the webhook is not yet registered, it utilizes default profile name as username.
  /// - If the webhook is already registered, it retrieves the stored username from [BreezPreferences].
  Future<String?> _resolveUsername() async {
    final bool isLnUrlWebhookRegistered = await breezPreferences.isLnUrlWebhookRegistered;

    if (!isLnUrlWebhookRegistered) {
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
  Future<String> _generateWebhookSignature(int time, String webhookUrl, String? username) async {
    _logger.info('Generating webhook signature');
    final String usernameComponent = username?.isNotEmpty == true ? '-$username' : '';
    final String message = '$time-$webhookUrl$usernameComponent';
    final String signature = await _signMessage(message);
    _logger.info('Successfully generated webhook signature');
    return signature;
  }

  /// Registers an LNURL webhook with the provided public key and request.
  ///
  ///  - Saves the username to [BreezPreferences] if present and
  ///  - Sets webhook as registered on [BreezPreferences] if succeeds
  Future<RegisterLnurlPayResponse> _registerLnurlWebhook({
    required String pubKey,
    required RegisterLnurlPayRequest request,
  }) async {
    final RegisterLnurlPayResponse registrationResponse = await lnAddressService.register(
      pubKey: pubKey,
      request: request,
    );

    final String? username = request.username;
    if (username != null && username.isNotEmpty) {
      await breezPreferences.setLnAddressUsername(username);
    }

    _logger.info(
      'Successfully registered LNURL Webhook: $registrationResponse',
    );

    await breezPreferences.setLnUrlWebhookRegistered();
    return registrationResponse;
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
