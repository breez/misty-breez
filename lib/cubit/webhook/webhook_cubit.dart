import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

export 'lnurl_pay_service.dart';
export 'webhook_service.dart';
export 'webhook_state.dart';

final Logger _logger = Logger('WebhookCubit');

class WebhookCubit extends Cubit<WebhookState> {
  final BreezSDKLiquid _breezSdkLiquid;
  final WebhookService _webhookService;
  final LnUrlPayService _lnUrlPayService;

  WebhookCubit(this._breezSdkLiquid, this._webhookService, this._lnUrlPayService) : super(WebhookState()) {
    _breezSdkLiquid.walletInfoStream.first.then(
      (GetInfoResponse getInfoResponse) => refreshWebhooks(walletInfo: getInfoResponse.walletInfo),
    );
  }

  Future<void> refreshWebhooks({WalletInfo? walletInfo, String? username}) async {
    _logger.info('Refreshing Webhooks');
    emit(WebhookState(isLoading: true));
    try {
      walletInfo = walletInfo ?? (await _breezSdkLiquid.instance?.getInfo())?.walletInfo;
      if (walletInfo != null) {
        final String webhookUrl = await _webhookService.generateWebhookURL();
        await _webhookService.registerWebhook(webhookUrl);
        final Map<String, String> lnUrlData = await _lnUrlPayService.registerLnurlpay(
          walletInfo,
          webhookUrl,
          username: username,
        );
        emit(
          WebhookState(
            lnurlPayUrl: lnUrlData['lnurl'],
            lnAddress: lnUrlData['lnAddress'],
          ),
        );
      } else {
        throw Exception('Unable to retrieve wallet information.');
      }
    } catch (err) {
      _logger.warning('Failed to refresh webhooks: $err');
      emit(
        WebhookState(
          webhookError: 'Failed to refresh Lightning Address:',
          webhookErrorTitle: err.toString(),
        ),
      );
    }
  }

  Future<void> updateLnAddressUsername({required String username}) async {
    emit(
      WebhookState(
        isLoading: true,
        lnAddress: state.lnAddress,
        lnurlPayUrl: state.lnurlPayUrl,
      ),
    );
    try {
      final GetInfoResponse? walletInfo = await _breezSdkLiquid.instance?.getInfo();
      if (walletInfo == null) {
        throw Exception('Failed to retrieve wallet info.');
      }
      final Map<String, String> lnUrlData = await _lnUrlPayService.updateLnAddressUsername(
        walletInfo.walletInfo,
        username,
      );
      emit(
        WebhookState(
          lnurlPayUrl: lnUrlData['lnurl'],
          lnAddress: lnUrlData['lnAddress'],
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          lnurlPayErrorTitle: 'Failed to update Lightning Address username:',
          lnurlPayError: err.toString(),
        ),
      );
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }
}
