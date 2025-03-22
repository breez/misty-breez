import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('Routes');

Route<dynamic>? onGenerateRoute({
  required RouteSettings settings,
  required GlobalKey<NavigatorState> homeNavigatorKey,
}) {
  _logger.info('New route: ${settings.name}');
  switch (settings.name) {
    case InitialWalkthroughPage.routeName:
      return FadeInRoute<void>(
        builder: (BuildContext _) => const InitialWalkthroughPage(),
        settings: settings,
      );
    case SplashPage.routeName:
      return FadeInRoute<void>(
        builder: (BuildContext _) => const SplashPage(),
        settings: settings,
      );
    case LockScreen.routeName:
      return NoTransitionRoute<void>(
        builder: (BuildContext _) => const LockScreen(
          authorizedAction: AuthorizedAction.launchHome,
        ),
        settings: settings,
      );
    case EnterMnemonicsPage.routeName:
      return FadeInRoute<String>(
        builder: (BuildContext _) => EnterMnemonicsPage(
          initialWords: settings.arguments as List<String>? ?? <String>[],
        ),
        settings: settings,
      );
    case Home.routeName:
      return FadeInRoute<void>(
        builder: (BuildContext _) => NavigatorPopHandler(
          onPopWithResult: (Object? result) => homeNavigatorKey.currentState!.maybePop(),
          child: Navigator(
            initialRoute: Home.routeName,
            key: homeNavigatorKey,
            onGenerateRoute: (RouteSettings settings) {
              _logger.info('New inner route: ${settings.name}');
              switch (settings.name) {
                case Home.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const Home(),
                    settings: settings,
                  );
                case ReceivePaymentPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: ReceivePaymentPage(
                        initialPageIndex: settings.arguments as int? ?? 0,
                      ),
                    ),
                    settings: settings,
                  );
                case ReceiveLightningAddressPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const ReceiveLightningAddressPage(),
                    settings: settings,
                  );
                case ReceiveLightningPaymentPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: const ReceiveLightningPaymentPage(),
                    ),
                    settings: settings,
                  );
                case ReceiveBitcoinAddressPaymentPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: const ReceiveBitcoinAddressPaymentPage(),
                    ),
                    settings: settings,
                  );
                case GetRefundPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const GetRefundPage(),
                    settings: settings,
                  );
                case RefundPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => RefundPage(
                      swapInfo: settings.arguments as RefundableSwap,
                    ),
                    settings: settings,
                  );
                case EnterPaymentInfoPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const EnterPaymentInfoPage(),
                    settings: settings,
                  );
                case SendChainSwapPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: SendChainSwapPage(
                        btcAddressData: settings.arguments as BitcoinAddressData?,
                      ),
                    ),
                    settings: settings,
                  );
                case LnPaymentPage.routeName:
                  return FadeInRoute<PrepareSendResponse?>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: LnPaymentPage(
                        lnInvoice: settings.arguments as LNInvoice,
                      ),
                    ),
                    settings: settings,
                  );
                case LnOfferPaymentPage.routeName:
                  return FadeInRoute<PrepareSendResponse?>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: LnOfferPaymentPage(
                        lnOfferPaymentArguments: settings.arguments as LnOfferPaymentArguments,
                      ),
                    ),
                    settings: settings,
                  );
                case LnUrlPaymentPage.routeName:
                  return FadeInRoute<PrepareLnUrlPayResponse?>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: LnUrlPaymentPage(
                        lnUrlPaymentArguments: settings.arguments as LnUrlPaymentArguments,
                      ),
                    ),
                    settings: settings,
                  );
                case FiatCurrencySettings.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const FiatCurrencySettings(),
                    settings: settings,
                  );
                case SecuritySettings.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const SecuredPage<SecuritySettings>(
                      securedWidget: SecuritySettings(),
                    ),
                    settings: settings,
                  );
                case MnemonicsConfirmationPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => MnemonicsConfirmationPage(
                      mnemonics: settings.arguments as String,
                    ),
                    settings: settings,
                  );
                case DevelopersView.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const DevelopersView(),
                    settings: settings,
                  );
                case QRScanView.routeName:
                  return MaterialPageRoute<String>(
                    fullscreenDialog: true,
                    builder: (BuildContext _) => const QRScanView(),
                    settings: settings,
                  );
              }
              assert(false);
              return null;
            },
          ),
        ),
        settings: settings,
      );
  }
  assert(false);
  return null;
}
