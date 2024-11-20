import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/dev/developers_view.dart';
import 'package:l_breez/routes/enter_payment_info/enter_payment_info_page.dart';
import 'package:l_breez/routes/fiat_currencies/fiat_currency_settings.dart';
import 'package:l_breez/routes/home/home.dart';
import 'package:l_breez/routes/initial_walkthrough/initial_walkthrough.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/enter_mnemonics_page.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/mnemonics_confirmation_page.dart';
import 'package:l_breez/routes/qr_scan/qr_scan.dart';
import 'package:l_breez/routes/receive_payment/receive_payment.dart';
import 'package:l_breez/routes/refund/refund.dart';
import 'package:l_breez/routes/security/lock_screen.dart';
import 'package:l_breez/routes/security/secured_page.dart';
import 'package:l_breez/routes/security/security_page.dart';
import 'package:l_breez/routes/send_payment/chainswap/chainswap.dart';
import 'package:l_breez/routes/send_payment/lightning/ln_payment_page.dart';
import 'package:l_breez/routes/send_payment/lnurl/lnurl_payment_page.dart';
import 'package:l_breez/routes/splash/splash_page.dart';
import 'package:l_breez/widgets/widgets.dart';
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
          onPop: () => homeNavigatorKey.currentState!.maybePop(),
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
                case LnUrlPaymentPage.routeName:
                  return FadeInRoute<PrepareLnUrlPayResponse?>(
                    builder: (BuildContext context) => BlocProvider<PaymentLimitsCubit>(
                      create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
                      child: LnUrlPaymentPage(
                        requestData: settings.arguments as LnUrlPayRequestData,
                      ),
                    ),
                    settings: settings,
                  );
                case FiatCurrencySettings.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const FiatCurrencySettings(),
                    settings: settings,
                  );
                case SecurityPage.routeName:
                  return FadeInRoute<void>(
                    builder: (BuildContext _) => const SecuredPage<SecurityPage>(
                      securedWidget: SecurityPage(),
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
                case QRScan.routeName:
                  return MaterialPageRoute<String>(
                    fullscreenDialog: true,
                    builder: (BuildContext _) => const QRScan(),
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
