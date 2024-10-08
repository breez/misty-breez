import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/app/app_theme_manager/app_theme_manager.dart';
import 'package:l_breez/app/routes/routes.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/home_page.dart';
import 'package:l_breez/routes/security/lock_screen.dart';
import 'package:l_breez/routes/splash/splash_page.dart';
import 'package:service_injector/service_injector.dart';
import 'package:theme_provider/theme_provider.dart';

class App extends StatelessWidget {
  final ServiceInjector injector;
  final SdkConnectivityCubit sdkConnectivityCubit;
  const App({super.key, required this.injector, required this.sdkConnectivityCubit});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountCubit>(
          create: (BuildContext context) => AccountCubit(injector.liquidSDK),
        ),
        BlocProvider<PaymentsCubit>(
          create: (BuildContext context) => PaymentsCubit(injector.liquidSDK),
        ),
        BlocProvider(
          create: (BuildContext context) => sdkConnectivityCubit,
        ),
        BlocProvider<RefundCubit>(
          create: (BuildContext context) => RefundCubit(injector.liquidSDK),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (BuildContext context) => ConnectivityCubit(),
        ),
        BlocProvider<InputCubit>(
          create: (BuildContext context) => InputCubit(
            injector.lightningLinks,
            injector.deviceClient,
          ),
        ),
        BlocProvider<UserProfileCubit>(
          create: (BuildContext context) => UserProfileCubit(),
        ),
        BlocProvider<WebhookCubit>(
          lazy: false,
          create: (BuildContext context) => WebhookCubit(
            injector.liquidSDK,
            injector.breezPreferences,
            injector.notifications,
          ),
        ),
        BlocProvider<CurrencyCubit>(
          create: (BuildContext context) => CurrencyCubit(injector.liquidSDK),
        ),
        BlocProvider<SecurityCubit>(
          create: (BuildContext context) => SecurityCubit(injector.keychain),
        ),
        BlocProvider<BackupCubit>(
          create: (BuildContext context) => BackupCubit(injector.liquidSDK),
        ),
        BlocProvider<LnUrlCubit>(
          create: (BuildContext context) => LnUrlCubit(injector.liquidSDK),
        ),
        BlocProvider<ChainSwapCubit>(
          create: (BuildContext context) => ChainSwapCubit(injector.liquidSDK),
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final GlobalKey _appKey = GlobalKey();
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AppThemeManager(
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, accountState) {
          return BlocBuilder<SecurityCubit, SecurityState>(builder: (context, securityState) {
            return MaterialApp(
              key: _appKey,
              title: "Misty ${getSystemAppLocalizations().app_name}",
              theme: ThemeProvider.themeOf(context).data,
              localizationsDelegates: localizationsDelegates(),
              supportedLocales: supportedLocales(),
              builder: (BuildContext context, Widget? child) {
                const kMaxTitleTextScaleFactor = 1.3;

                return MediaQuery.withClampedTextScaling(
                  maxScaleFactor: kMaxTitleTextScaleFactor,
                  child: child!,
                );
              },
              initialRoute: securityState.pinStatus == PinStatus.enabled
                  ? LockScreen.routeName
                  : accountState.initial
                      ? SplashPage.routeName
                      : Home.routeName,
              onGenerateRoute: (RouteSettings settings) => onGenerateRoute(
                settings: settings,
                homeNavigatorKey: _homeNavigatorKey,
              ),
            );
          });
        },
      ),
    );
  }
}
