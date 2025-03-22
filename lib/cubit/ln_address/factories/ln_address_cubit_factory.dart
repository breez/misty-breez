import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:service_injector/service_injector.dart';

class LnAddressCubitFactory {
  static LnAddressCubit create(ServiceInjector injector) {
    final BreezSDKLiquid breezSdkLiquid = injector.breezSdkLiquid;
    final BreezPreferences breezPreferences = injector.breezPreferences;
    final WebhookService webhookService = WebhookService(breezSdkLiquid, injector.notifications);

    final MessageSigner messageSigner = MessageSigner(breezSdkLiquid);
    final WebhookRequestBuilder requestBuilder = WebhookRequestBuilder(messageSigner);
    final UsernameResolver usernameResolver = UsernameResolver(breezPreferences);
    final LnUrlPayService lnAddressService = LnUrlPayService();

    final LnUrlRegistrationManager registrationManager = LnUrlRegistrationManager(
      lnAddressService: lnAddressService,
      breezPreferences: breezPreferences,
      requestBuilder: requestBuilder,
      usernameResolver: usernameResolver,
      webhookService: webhookService,
    );

    return LnAddressCubit(
      breezSdkLiquid: breezSdkLiquid,
      registrationManager: registrationManager,
    );
  }
}
