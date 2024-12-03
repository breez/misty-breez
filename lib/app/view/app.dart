import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/app/app.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:nested/nested.dart';
import 'package:service_injector/service_injector.dart';
import 'package:theme_provider/theme_provider.dart';

class App extends StatelessWidget {
  final ServiceInjector injector;
  final SdkConnectivityCubit sdkConnectivityCubit;

  const App({
    required this.injector,
    required this.sdkConnectivityCubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<AccountCubit>(
          lazy: false,
          create: (BuildContext context) => AccountCubit(injector.breezSdkLiquid),
        ),
        BlocProvider<PaymentsCubit>(
          create: (BuildContext context) => PaymentsCubit(injector.breezSdkLiquid),
        ),
        BlocProvider<SdkConnectivityCubit>(
          create: (BuildContext context) => sdkConnectivityCubit,
        ),
        BlocProvider<RefundCubit>(
          create: (BuildContext context) => RefundCubit(injector.breezSdkLiquid),
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
            injector.breezSdkLiquid,
            injector.breezPreferences,
            injector.notifications,
          ),
        ),
        BlocProvider<CurrencyCubit>(
          create: (BuildContext context) => CurrencyCubit(injector.breezSdkLiquid),
        ),
        BlocProvider<SecurityCubit>(
          create: (BuildContext context) => SecurityCubit(injector.keychain),
        ),
        BlocProvider<BackupCubit>(
          create: (BuildContext context) => BackupCubit(injector.breezSdkLiquid),
        ),
        BlocProvider<LnUrlCubit>(
          create: (BuildContext context) => LnUrlCubit(injector.breezSdkLiquid),
        ),
        BlocProvider<ChainSwapCubit>(
          create: (BuildContext context) => ChainSwapCubit(injector.breezSdkLiquid),
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
  late Future<bool> _isOnboardingCompleteFuture;

  @override
  void initState() {
    super.initState();
    _isOnboardingCompleteFuture = OnboardingPreferences.isOnboardingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isOnboardingCompleteFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return Container(color: breezLightTheme.canvasColor);
        }

        final bool isOnboardingComplete = snapshot.data ?? false;

        return AppThemeManager(
          child: BlocBuilder<AccountCubit, AccountState>(
            builder: (BuildContext context, AccountState accountState) {
              return BlocBuilder<SecurityCubit, SecurityState>(
                builder: (BuildContext context, SecurityState securityState) {
                  return MaterialApp(
                    key: _appKey,
                    title: 'Misty ${getSystemAppLocalizations().app_name}',
                    theme: ThemeProvider.themeOf(context).data,
                    localizationsDelegates: localizationsDelegates(),
                    supportedLocales: supportedLocales(),
                    builder: (BuildContext context, Widget? child) {
                      const double kMaxTitleTextScaleFactor = 1.3;

                      return MediaQuery.withClampedTextScaling(
                        maxScaleFactor: kMaxTitleTextScaleFactor,
                        child: child!,
                      );
                    },
                    initialRoute: securityState.pinStatus == PinStatus.enabled
                        ? LockScreen.routeName
                        : !isOnboardingComplete
                            ? SplashPage.routeName
                            : Home.routeName,
                    onGenerateRoute: (RouteSettings settings) => onGenerateRoute(
                      settings: settings,
                      homeNavigatorKey: _homeNavigatorKey,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
