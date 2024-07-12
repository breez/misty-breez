import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/bloc/account/account_bloc.dart';
import 'package:l_breez/bloc/account/account_state.dart';
import 'package:l_breez/bloc/ext/block_builder_extensions.dart';
import 'package:l_breez/bloc/security/security_bloc.dart';
import 'package:l_breez/bloc/security/security_state.dart';
import 'package:l_breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:l_breez/bloc/user_profile/user_profile_state.dart';
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
import 'package:l_breez/theme/breez_dark_theme.dart';
import 'package:l_breez/theme/breez_light_theme.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:logging/logging.dart';
import 'package:theme_provider/theme_provider.dart';

const String THEME_ID_PREFERENCE_KEY = "themeID";

final _log = Logger("UserApp");

const _kMaxTitleTextScaleFactor = 1.3;

class UserApp extends StatelessWidget {
  final GlobalKey _appKey = GlobalKey();
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();

  UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      saveThemesOnChange: true,
      onInitCallback: (controller, previouslySavedThemeFuture) async {
        String? savedTheme = await previouslySavedThemeFuture;
        if (savedTheme != null) {
          controller.setTheme(savedTheme);
        } else {
          controller.setTheme('light');
          controller.forgetSavedTheme();
        }
      },
      themes: <AppTheme>[
        AppTheme(
          id: 'light',
          data: breezLightTheme,
          description: 'Blue Theme',
        ),
        AppTheme(
          id: 'dark',
          data: breezDarkTheme,
          description: 'Dark Theme',
        ),
      ],
      child: ThemeConsumer(
        child: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, state) {
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                systemNavigationBarColor: ThemeProvider.themeOf(context).data.bottomAppBarTheme.color,
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.dark, // iOS
                statusBarIconBrightness: Brightness.light, // Android
                systemNavigationBarContrastEnforced: false,
                systemStatusBarContrastEnforced: false,
              ),
            );
            return BlocBuilder2<AccountBloc, AccountState, SecurityBloc, SecurityState>(
                builder: (context, accState, securityState) {
              return MaterialApp(
                key: _appKey,
                title: "Misty ${getSystemAppLocalizations().app_name}",
                theme: ThemeProvider.themeOf(context).data,
                localizationsDelegates: localizationsDelegates(),
                supportedLocales: supportedLocales(),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery.withClampedTextScaling(
                    maxScaleFactor: _kMaxTitleTextScaleFactor,
                    child: child!,
                  );
                },
                initialRoute: securityState.pinStatus == PinStatus.enabled ? "lockscreen" : "splash",
                onGenerateRoute: (RouteSettings settings) {
                  _log.info("New route: ${settings.name}");
                  switch (settings.name) {
                    case '/intro':
                      return FadeInRoute(
                        builder: (_) => const InitialWalkthroughPage(),
                        settings: settings,
                      );
                    case 'splash':
                      return FadeInRoute(
                        builder: (_) => SplashPage(isInitial: accState.initial),
                        settings: settings,
                      );
                    case 'lockscreen':
                      return NoTransitionRoute(
                        builder: (_) => const LockScreen(
                          authorizedAction: AuthorizedAction.launchHome,
                        ),
                        settings: settings,
                      );
                    case '/enter_mnemonics':
                      return FadeInRoute<String>(
                        builder: (_) => EnterMnemonicsPage(
                          initialWords: settings.arguments as List<String>? ?? [],
                        ),
                        settings: settings,
                      );
                    case '/':
                      return FadeInRoute(
                        builder: (_) => NavigatorPopHandler(
                          onPop: () => _homeNavigatorKey.currentState!.maybePop(),
                          child: Navigator(
                            initialRoute: "/",
                            key: _homeNavigatorKey,
                            onGenerateRoute: (RouteSettings settings) {
                              _log.info("New inner route: ${settings.name}");
                              switch (settings.name) {
                                case '/':
                                  return FadeInRoute(
                                    builder: (_) => const Home(),
                                    settings: settings,
                                  );
                                case '/create_invoice':
                                  return FadeInRoute(
                                    builder: (_) => const CreateInvoicePage(),
                                    settings: settings,
                                  );
                                case '/receive_chainswap':
                                  return FadeInRoute(
                                    builder: (_) => const ReceiveChainSwapPage(),
                                    settings: settings,
                                  );
                                case '/send_chainswap':
                                  return FadeInRoute(
                                    builder: (_) => SendChainSwapPage(
                                      btcAddressData: settings.arguments as BitcoinAddressData?,
                                    ),
                                    settings: settings,
                                  );
                                case '/fiat_currency':
                                  return FadeInRoute(
                                    builder: (_) => const FiatCurrencySettings(),
                                    settings: settings,
                                  );
                                case '/security':
                                  return FadeInRoute(
                                    builder: (_) => const SecuredPage(
                                      securedWidget: SecurityPage(),
                                    ),
                                    settings: settings,
                                  );
                                case '/mnemonics':
                                  return FadeInRoute(
                                    builder: (_) => MnemonicsConfirmationPage(
                                      mnemonics: settings.arguments as String,
                                    ),
                                    settings: settings,
                                  );
                                case '/developers':
                                  return FadeInRoute(
                                    builder: (_) => const DevelopersView(),
                                    settings: settings,
                                  );
                                case '/qr_scan':
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
                },
              );
            });
          },
        ),
      ),
    );
  }
}
