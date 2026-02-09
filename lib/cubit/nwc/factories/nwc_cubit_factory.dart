import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:service_injector/service_injector.dart';

class NwcCubitFactory {
  static NwcCubit of(BuildContext context) =>
      create(ServiceInjector(), context.read<PermissionsCubit>());

  static NwcCubit create(ServiceInjector injector, PermissionsCubit permissionsCubit) {
    final BreezSDKLiquid breezSdkLiquid = injector.breezSdkLiquid;
    final MessageSigner messageSigner = MessageSigner(breezSdkLiquid);
    final NwcWebhookRequestBuilder requestBuilder = NwcWebhookRequestBuilder(messageSigner);
    final NwcWebhookService webhookService = NwcWebhookService(
      breezSdkLiquid,
      injector.notifications,
      permissionsCubit,
    );
    final NwcRegistrationManager nwcRegistrationManager = NwcRegistrationManager(
      requestBuilder: requestBuilder,
      webhookService: webhookService,
    );

    return NwcCubit(breezSdkLiquid: breezSdkLiquid, nwcRegistrationManager: nwcRegistrationManager);
  }
}
