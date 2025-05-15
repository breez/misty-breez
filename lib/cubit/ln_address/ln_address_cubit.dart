import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'factories/factories.dart';
export 'ln_address_state.dart';
export 'models/models.dart';
export 'services/services.dart';
export 'utils/utils.dart';

final Logger _logger = Logger('LnAddressCubit');

class LnAddressCubit extends Cubit<LnAddressState> {
  final BreezSDKLiquid breezSdkLiquid;
  final LnUrlRegistrationManager registrationManager;

  LnAddressCubit({
    required this.breezSdkLiquid,
    required this.registrationManager,
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
    final String registrationType = _determineRegistrationType(isRecover, baseUsername);
    final String actionMessage = _getActionMessage(registrationType, baseUsername);

    _logger.info(actionMessage);
    _updateStateForOperation(registrationType);

    try {
      pubKey = pubKey ?? await _getPubKey();
      final String webhookUrl = await registrationManager.setupWebhook(pubKey);
      final String? offer = await _getBolt12Offer();

      final RegisterRecoverLnurlPayResponse response = await registrationManager.performRegistration(
        pubKey: pubKey,
        webhookUrl: webhookUrl,
        registrationType: registrationType,
        baseUsername: baseUsername,
        offer: offer,
      );

      emit(
        LnAddressState(
          status: LnAddressStatus.success,
          lnurl: response.lnurl,
          lnAddress: response.lightningAddress,
          updateStatus: registrationType == RegistrationType.update
              ? const LnAddressUpdateStatus(status: UpdateStatus.success)
              : state.updateStatus,
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to $actionMessage', e, stackTrace);
      _updateStateForError(e, registrationType, actionMessage);
    }
  }

  String _determineRegistrationType(bool isRecover, String? baseUsername) {
    if (isRecover) {
      return RegistrationType.recovery;
    }
    if (baseUsername != null) {
      return RegistrationType.update;
    }
    return RegistrationType.newRegistration;
  }

  String _getActionMessage(String registrationType, String? baseUsername) {
    switch (registrationType) {
      case RegistrationType.recovery:
        return 'Recovering Lightning Address';
      case RegistrationType.update:
        return 'Update LN Address Username to: $baseUsername';
      case RegistrationType.newRegistration:
      default:
        return 'Setup Lightning Address';
    }
  }

  void _updateStateForOperation(String registrationType) {
    final bool isUpdating = registrationType == RegistrationType.update;

    emit(
      state.copyWith(
        status: isUpdating ? state.status : LnAddressStatus.loading,
        updateStatus: isUpdating ? const LnAddressUpdateStatus(status: UpdateStatus.loading) : null,
      ),
    );
  }

  void _updateStateForError(Object e, String registrationType, String actionMessage) {
    final bool isUpdating = registrationType == RegistrationType.update;

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

  Future<String> _getPubKey() async {
    final WalletInfo walletInfo = await _getWalletInfo();
    return walletInfo.pubkey;
  }

  Future<WalletInfo> _getWalletInfo() async {
    return (await breezSdkLiquid.instance?.getInfo())?.walletInfo ??
        (throw Exception('Failed to retrieve wallet info'));
  }

  /// Clears any update status errors or messages
  void clearUpdateStatus() {
    _logger.info('Clearing LnAddressUpdateStatus');
    emit(state.clearUpdateStatus());
  }

  Future<String?> _getBolt12Offer() async {
    try {
      final BindingLiquidSdk sdkInstance = breezSdkLiquid.instance!;
      const PrepareReceiveRequest prepareReq = PrepareReceiveRequest(
        paymentMethod: PaymentMethod.bolt12Offer,
      );
      final PrepareReceiveResponse prepareRes = await sdkInstance.prepareReceivePayment(req: prepareReq);
      final ReceivePaymentRequest receiveReq = ReceivePaymentRequest(prepareResponse: prepareRes);
      final ReceivePaymentResponse receiveRes = await sdkInstance.receivePayment(req: receiveReq);
      return receiveRes.destination;
    } catch (e, stackTrace) {
      _logger.warning('Failed to get BOLT12 Offer', e, stackTrace);
      return null;
    }
  }

  /// Clears any error state
  void clearError() {
    _logger.info('Clearing LnAddress error state');
    emit(state.clearError());
  }
}
