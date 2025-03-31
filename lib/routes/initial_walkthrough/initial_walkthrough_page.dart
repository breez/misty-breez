import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:theme_provider/theme_provider.dart';

class InitialWalkthroughPage extends StatefulWidget {
  static const String routeName = '/intro';

  const InitialWalkthroughPage({super.key});

  @override
  State createState() => InitialWalkthroughPageState();
}

class InitialWalkthroughPageState extends State<InitialWalkthroughPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ThemeController themeProvider = ThemeProvider.controllerOf(context);
      themeProvider.setTheme('light');
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: BreezColors.blue[500],
      ),
      child: Theme(
        data: breezLightTheme,
        child: const Scaffold(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Spacer(flex: 3),
                AnimatedLogo(),
                Spacer(flex: 3),
                InitialWalkthroughActions(),
                Spacer(),
                NavigationDrawerFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
