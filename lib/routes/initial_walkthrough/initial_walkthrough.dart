import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/initial_walkthrough/beta_warning_dialog.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/enter_mnemonics_page.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:logging/logging.dart';
import 'package:theme_provider/theme_provider.dart';

final _logger = Logger("InitialWalkthrough");

class InitialWalkthroughPage extends StatefulWidget {
  static const routeName = "/intro";

  const InitialWalkthroughPage({super.key});

  @override
  State createState() => InitialWalkthroughPageState();
}

class InitialWalkthroughPageState extends State<InitialWalkthroughPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _controller;
  Animation<int>? _animation;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = ThemeProvider.controllerOf(context);
      themeProvider.setTheme('light');
    });
    _startBreezLogoAnimation();
  }

  void _startBreezLogoAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2720),
    )..forward(from: 0.0);
    _animation = IntTween(begin: 0, end: 67).animate(_controller!);
    if (_controller!.isCompleted) {
      _controller!.stop();
      _controller!.dispose();
    }
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: BreezColors.blue[500],
      ),
      child: Theme(
        data: breezLightTheme,
        child: Scaffold(
          key: _scaffoldKey,
          body: Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 200,
                      child: Container(),
                    ),
                    Expanded(
                      flex: 171,
                      child: AnimatedBuilder(
                        animation: _animation!,
                        builder: (BuildContext context, Widget? child) {
                          String frame = _animation!.value.toString().padLeft(2, '0');
                          return Image.asset(
                            'assets/animations/welcome/frame_${frame}_delay-0.04s.png',
                            gaplessPlayback: true,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 200,
                      child: Container(),
                    ),
                    Expanded(
                      flex: 48,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        child: AutoSizeText(
                          texts.initial_walk_through_welcome_message,
                          textAlign: TextAlign.center,
                          style: welcomeTextStyle,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 60,
                      child: Container(),
                    ),
                    SizedBox(
                      height: 48.0,
                      width: 168.0,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          backgroundColor: themeData.primaryColor,
                          elevation: 0.0,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          texts.initial_walk_through_lets_breeze,
                          style: themeData.textTheme.labelLarge,
                        ),
                        onPressed: () => _letsBreez(),
                      ),
                    ),
                    Expanded(
                      flex: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: GestureDetector(
                          onTap: () => _restoreWalletFromMnemonicSeed(),
                          child: Text(
                            texts.initial_walk_through_restore_from_backup,
                            style: restoreLinkStyle,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 120,
                      child: Container(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _letsBreez() async {
    _logger.info("Lets breez");
    bool approved = await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const BetaWarningDialog();
      },
    );
    if (approved) connect();
  }

  void connect({String? mnemonic}) async {
    final connectionService = context.read<SdkConnectivityCubit>();
    final securityCubit = context.read<SecurityCubit>();
    final accountCubit = context.read<AccountCubit>();

    final isRestore = mnemonic != null;
    _logger.info("${isRestore ? "Restore" : "Starting new"} wallet");
    final texts = context.texts();
    final navigator = Navigator.of(context);
    var loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);

    final themeProvider = ThemeProvider.controllerOf(context);
    try {
      if (isRestore) {
        await connectionService.restore(mnemonic: mnemonic);
        securityCubit.mnemonicsValidated();
        accountCubit.setIsRestoring(true);
      } else {
        await connectionService.register();
      }
      accountCubit.setOnboardingComplete(true);
      themeProvider.setTheme('dark');
      navigator.pushReplacementNamed('/');
    } catch (error) {
      _logger.info("Failed to ${isRestore ? "restore" : "register"} wallet", error);
      if (isRestore) {
        _restoreWalletFromMnemonicSeed(initialWords: mnemonic.split(" "));
      }
      if (!mounted) return;
      showFlushbar(context, message: extractExceptionMessage(error, texts));
      return;
    } finally {
      navigator.removeRoute(loaderRoute);
    }
  }

  void _restoreWalletFromMnemonicSeed({
    List<String>? initialWords,
  }) async {
    _logger.info("Restore wallet from mnemonic seed");
    String? mnemonic = await _getMnemonic(initialWords: initialWords);
    if (mnemonic != null) {
      connect(mnemonic: mnemonic);
    }
  }

  Future<String?> _getMnemonic({
    List<String>? initialWords,
  }) async {
    _logger.info("Get mnemonic, initialWords: ${initialWords?.length}");
    return await Navigator.of(context).pushNamed<String>(
      EnterMnemonicsPage.routeName,
      arguments: initialWords,
    );
  }
}
