import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:theme_provider/theme_provider.dart';

class AppThemeManager extends StatelessWidget {
  final Widget child;

  const AppThemeManager({super.key, required this.child});

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
        child: Builder(
          builder: (context) {
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
            return child;
          },
        ),
      ),
    );
  }
}
