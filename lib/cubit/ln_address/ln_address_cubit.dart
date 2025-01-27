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

class LnAddressCubit extends Cubit<LnAddressState> {
  final BreezSDKLiquid breezSdkLiquid;
  final BreezPreferences breezPreferences;
  final LnAddressService lnAddressService;
  final WebhookService webhookService;

  LnAddressCubit({
    required this.breezSdkLiquid,
    required this.breezPreferences,
    required this.lnAddressService,
    required this.webhookService,
  }) : super(const LnAddressState());

  Future<void> setupLightningAddress({String? username}) async {
    final bool isUpdate = username != null;
    _logger.info(isUpdate ? 'Updating username to: $username' : 'Initializing lightning address');

    emit(
      state.copyWith(
        status: isUpdate ? state.status : LnAddressStatus.loading,
        updateStatus: isUpdate ? const LnAddressUpdateStatus(status: UpdateStatus.loading) : null,
      ),
    );

    try {
      final LnAddressRegistrationResponse registrationResponse = await _setupAndRegisterLnAddress(
        username: username,
      );

      emit(
        state.copyWith(
          status: LnAddressStatus.success,
          lnurl: registrationResponse.lnurl,
          lnAddress: registrationResponse.lnAddress,
          updateStatus: isUpdate ? const LnAddressUpdateStatus(status: UpdateStatus.success) : null,
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe(
        isUpdate ? 'Failed to update username' : 'Failed to initialize lightning address',
        e,
        stackTrace,
      );

      if (isUpdate) {
        final String errorMessage = e is LnAddressRegistrationException
            ? (e.responseBody?.isNotEmpty == true ? e.responseBody! : e.message)
            : 'Failed to update username';

        emit(
          state.copyWith(
            updateStatus: LnAddressUpdateStatus(
              status: UpdateStatus.error,
              error: e,
              errorMessage: errorMessage,
            ),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: LnAddressStatus.error,
            error: e,
          ),
        );
      }
    }
  }

  Future<LnAddressRegistrationResponse> _setupAndRegisterLnAddress({String? username}) async {
    final WalletInfo? walletInfo = (await breezSdkLiquid.instance?.getInfo())?.walletInfo;
    if (walletInfo == null) {
      throw Exception('Failed to retrieve wallet info');
    }

    final String webhookUrl = await webhookService.generateWebhookUrl();
    await _invalidateExistingWebhookIfNeeded(pubKey: walletInfo.pubkey, webhookUrl: webhookUrl);
    await webhookService.register(webhookUrl);
    await breezPreferences.setWebhookUrl(webhookUrl);

    final LnAddressRegistrationResponse registrationResponse = await _registerLnAddressWebhook(
      pubKey: walletInfo.pubkey,
      webhookUrl: webhookUrl,
      username: username,
    );

    return registrationResponse;
  }

  Future<void> _invalidateExistingWebhookIfNeeded({
    required String pubKey,
    required String webhookUrl,
  }) async {
    final String? existingWebhook = await breezPreferences.getWebhookUrl();
    if (existingWebhook != null && existingWebhook != webhookUrl) {
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final String message = '$timestamp-$existingWebhook';
      final String signature = await _signMessage(message);

      final InvalidateWebhookRequest invalidateWebhookRequest = InvalidateWebhookRequest(
        webhookUrl: existingWebhook,
        signature: signature,
        timestamp: timestamp,
      );
      await lnAddressService.invalidateWebhook(pubKey, invalidateWebhookRequest);
      breezPreferences.clearWebhookUrl();
    }
  }

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

  Future<LnAddressRegistrationResponse> _registerLnAddressWebhook({
    required String pubKey,
    required String webhookUrl,
    String? username,
  }) async {
    _logger.info('Preparing LnAddressRegistrationRequest');
    _logger.info('Initial parameters: pubKey=$pubKey, webhookUrl=$webhookUrl, username=$username');

    try {
      if (username == null || username.isEmpty) {
        if (await breezPreferences.isLnAddressSetup()) {
          final String? profileName = await breezPreferences.getProfileName();
          username = UsernameFormatter.formatDefaultProfileName(profileName);
          _logger.info('Initial setup: using formatted profile name: $username');
        } else {
          username = await breezPreferences.getLnAddressUsername();
          _logger.info('Using stored username: $username');
        }
      }

      final String signature = await _generateWebhookSignature(webhookUrl, username);

      final LnAddressRegistrationRequest request = LnAddressRegistrationRequest(
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        webhookUrl: webhookUrl,
        signature: signature,
        username: username,
      );
      _logger.fine('Created LnAddressRegistrationRequest with timestamp: ${request.timestamp}');

      final LnAddressRegistrationResponse registrationResponse = await lnAddressService.register(
        pubKey: pubKey,
        request: request,
      );

      if (username != null && username.isNotEmpty) {
        await breezPreferences.setLnAddressUsername(username);
        _logger.info('Stored username in secure storage: $username');
      }

      _logger.info(
        'Successfully registered Lightning Address: $registrationResponse',
      );

      await breezPreferences.completeLnAddressSetup();

      return registrationResponse;
    } catch (e, stackTrace) {
      _logger.severe('Failed to register Lightning Address', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _generateWebhookSignature(String webhookUrl, String? username) async {
    _logger.info('Generating webhook signature');
    final String usernameComponent = username?.isNotEmpty == true ? '-$username' : '';
    final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String message = '$timestamp-$webhookUrl$usernameComponent';

    final String signature = await _signMessage(message);
    _logger.info('Successfully generated webhook signature');
    return signature;
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

class LnAddressCubitFactory {
  static LnAddressCubit create(ServiceInjector injector) {
    final BreezSDKLiquid breezSdkLiquid = injector.breezSdkLiquid;
    final BreezPreferences breezPreferences = injector.breezPreferences;

    final WebhookService webhookService = WebhookService(breezSdkLiquid, injector.notifications);

    return LnAddressCubit(
      breezSdkLiquid: breezSdkLiquid,
      breezPreferences: breezPreferences,
      lnAddressService: LnAddressService(),
      webhookService: webhookService,
    );
  }
}
