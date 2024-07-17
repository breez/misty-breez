import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/chainswap/receive/receive_chainswap_page.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_page.dart';
import 'package:l_breez/routes/create_invoice/create_invoice_page.dart';
import 'package:l_breez/routes/dev/developers_view.dart';
import 'package:l_breez/routes/fiat_currencies/fiat_currency_settings.dart';
import 'package:l_breez/routes/home/home_page.dart';
import 'package:l_breez/routes/initial_walkthrough/initial_walkthrough.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/enter_mnemonics_page.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/mnemonics_confirmation_page.dart';
import 'package:l_breez/routes/qr_scan/qr_scan.dart';
import 'package:l_breez/routes/security/lock_screen.dart';
import 'package:l_breez/routes/security/secured_page.dart';
import 'package:l_breez/routes/security/security_page.dart';
import 'package:l_breez/routes/splash/splash_page.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:logging/logging.dart';

final _log = Logger("Routes");

Route? onGenerateRoute({
  required RouteSettings settings,
  required GlobalKey<NavigatorState> homeNavigatorKey,
  required accountState,
  required SecurityState securityState,
}) {
  _log.info("New route: ${settings.name}");
  switch (settings.name) {
    case InitialWalkthroughPage.routeName:
      return FadeInRoute(
        builder: (_) => const InitialWalkthroughPage(),
        settings: settings,
      );
    case SplashPage.routeName:
      return FadeInRoute(
        builder: (_) => SplashPage(isInitial: accountState.initial),
        settings: settings,
      );
    case LockScreen.routeName:
      return NoTransitionRoute(
        builder: (_) => const LockScreen(
          authorizedAction: AuthorizedAction.launchHome,
        ),
        settings: settings,
      );
    case EnterMnemonicsPage.routeName:
      return FadeInRoute<String>(
        builder: (_) => EnterMnemonicsPage(
          initialWords: settings.arguments as List<String>? ?? [],
        ),
        settings: settings,
      );
    case Home.routeName:
      return FadeInRoute(
        builder: (_) => NavigatorPopHandler(
          onPop: () => homeNavigatorKey.currentState!.maybePop(),
          child: Navigator(
            initialRoute: Home.routeName,
            key: homeNavigatorKey,
            onGenerateRoute: (RouteSettings settings) {
              _log.info("New inner route: ${settings.name}");
              switch (settings.name) {
                case Home.routeName:
                  return FadeInRoute(
                    builder: (_) => const Home(),
                    settings: settings,
                  );
                case CreateInvoicePage.routeName:
                  return FadeInRoute(
                    builder: (_) => const CreateInvoicePage(),
                    settings: settings,
                  );
                case ReceiveChainSwapPage.routeName:
                  return FadeInRoute(
                    builder: (_) => const ReceiveChainSwapPage(),
                    settings: settings,
                  );
                case SendChainSwapPage.routeName:
                  return FadeInRoute(
                    builder: (_) => SendChainSwapPage(
                      btcAddressData: settings.arguments as BitcoinAddressData?,
                    ),
                    settings: settings,
                  );
                case FiatCurrencySettings.routeName:
                  return FadeInRoute(
                    builder: (_) => const FiatCurrencySettings(),
                    settings: settings,
                  );
                case SecurityPage.routeName:
                  return FadeInRoute(
                    builder: (_) => const SecuredPage(
                      securedWidget: SecurityPage(),
                    ),
                    settings: settings,
                  );
                case MnemonicsConfirmationPage.routeName:
                  return FadeInRoute(
                    builder: (_) => MnemonicsConfirmationPage(
                      mnemonics: settings.arguments as String,
                    ),
                    settings: settings,
                  );
                case DevelopersView.routeName:
                  return FadeInRoute(
                    builder: (_) => const DevelopersView(),
                    settings: settings,
                  );
                case QRScan.routeName:
                  return MaterialPageRoute<String>(
                    fullscreenDialog: true,
                    builder: (_) => const QRScan(),
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
