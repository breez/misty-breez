import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:theme_provider/theme_provider.dart';

class AppThemeManager extends StatefulWidget {
  final Widget child;

  const AppThemeManager({required this.child, super.key});

  @override
  AppThemeManagerState createState() => AppThemeManagerState();
}

class AppThemeManagerState extends State<AppThemeManager> {
  late Future<void> loadThemeFromDiskFuture;

  @override
  void initState() {
    super.initState();
    loadThemeFromDiskFuture = _loadThemeFromDiskFuture();
  }

  Future<void> _loadThemeFromDiskFuture() async {
    return await ThemeProvider.controllerOf(context).loadThemeFromDisk();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      saveThemesOnChange: true,
      onInitCallback: (ThemeController controller, Future<String?> previouslySavedThemeFuture) async {
        final String? savedTheme = await previouslySavedThemeFuture;
        if (savedTheme != null) {
          controller.setTheme(savedTheme);
        } else {
          controller.setTheme('dark');
          controller.forgetSavedTheme();
        }
      },
      themes: <AppTheme>[
        AppTheme(id: 'dark', data: breezDarkTheme, description: 'Dark Theme'),
        AppTheme(id: 'light', data: breezLightTheme, description: 'Blue Theme'),
      ],
      child: FutureBuilder<void>(
        future: loadThemeFromDiskFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          return ThemeConsumer(
            child: Builder(
              builder: (BuildContext context) {
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
                return widget.child;
              },
            ),
          );
        },
      ),
    );
  }
}
