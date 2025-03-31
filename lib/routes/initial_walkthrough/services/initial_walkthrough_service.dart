import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:theme_provider/theme_provider.dart';

/// Service that handles wallet registration and restoration workflows.
class InitialWalkthroughService {
  static final Logger _logger = Logger('InitialWalkthroughService');

  final BuildContext _context;
  late final SdkConnectivityCubit _connectionService;
  late final AccountCubit _accountCubit;
  late final SecurityCubit _securityCubit;

  /// Creates a service instance with required dependencies.
  InitialWalkthroughService(this._context) {
    _initializeDependencies();
  }

  /// Initialize dependencies using the provided context.
  void _initializeDependencies() {
    _connectionService = _context.read<SdkConnectivityCubit>();
    _accountCubit = _context.read<AccountCubit>();
    _securityCubit = _context.read<SecurityCubit>();
  }

  /// Starts the wallet registration process after confirming with user.
  Future<void> registerWallet() async {
    _logger.info("Let's Breez!");
    if (!await _confirmBetaDisclaimer()) {
      return;
    }

    await _connect();
  }

  /// Starts the wallet restoration process using a mnemonic seed.
  Future<void> restoreWallet({List<String>? initialWords}) async {
    _logger.info('Restore wallet from mnemonic seed');
    final String? mnemonic = await _getMnemonic(initialWords: initialWords);
    if (mnemonic == null) {
      return;
    }

    await _connect(mnemonic: mnemonic);
  }

  /// Prompts the user with a beta disclaimer and requests confirmation.
  Future<bool> _confirmBetaDisclaimer() async {
    return await showDialog<bool>(
          useRootNavigator: false,
          context: _context,
          barrierDismissible: false,
          builder: (_) => const BetaWarningDialog(),
        ) ??
        false;
  }

  /// Gets the mnemonic seed from user input.
  Future<String?> _getMnemonic({List<String>? initialWords}) async {
    _logger.info('Get mnemonic, initialWords: ${initialWords?.length}');
    return Navigator.of(_context).pushNamed<String>(
      EnterMnemonicsPage.routeName,
      arguments: initialWords,
    );
  }

  /// Connects to the wallet using either a new wallet or restored mnemonic.
  Future<void> _connect({String? mnemonic}) async {
    final bool isRestoring = mnemonic != null;
    _logger.info(isRestoring ? 'Restoring wallet' : 'Starting new wallet');

    final NavigatorState navigator = Navigator.of(_context);
    final TransparentPageRoute<void> loaderRoute = _showLoaderOverlay(navigator);

    try {
      isRestoring ? await _restoreExistingWallet(mnemonic) : await _registerNewWallet();
      await _completeOnboarding();
      navigator.pushReplacementNamed('/');
    } catch (error) {
      _handleConnectionError(error, mnemonic);
    } finally {
      _hideLoaderOverlay(navigator, loaderRoute);
    }
  }

  /// Restores an existing wallet using a mnemonic.
  Future<void> _restoreExistingWallet(String mnemonic) async {
    await _connectionService.restore(mnemonic: mnemonic);
    await _securityCubit.completeMnemonicVerification();
    _accountCubit.setIsRestoring(true);
  }

  /// Registers a new wallet.
  Future<void> _registerNewWallet() async {
    await _connectionService.register();
  }

  /// Completes the onboarding process.
  Future<void> _completeOnboarding() async {
    await OnboardingPreferences.setOnboardingComplete(true);
    if (_context.mounted) {
      ThemeProvider.controllerOf(_context).setTheme('dark');
    }
  }

  /// Handles errors that occur during wallet connection.
  void _handleConnectionError(Object error, String? mnemonic) {
    final bool isRestoring = mnemonic != null;
    _logger.info("Failed to ${isRestoring ? "restore" : "register"} wallet.", error);

    if (isRestoring && _context.mounted) {
      restoreWallet(initialWords: mnemonic.split(' '));
      return;
    }

    if (_context.mounted) {
      showFlushbar(_context, message: ExceptionHandler.extractMessage(error, _context.texts()));
    }
  }

  /* UI Helpers */

  /// Shows a loader overlay and returns the route for later removal.
  TransparentPageRoute<void> _showLoaderOverlay(NavigatorState navigator) {
    final TransparentPageRoute<void> route = createLoaderRoute(_context);
    navigator.push(route);
    return route;
  }

  /// Hides the loader overlay.
  void _hideLoaderOverlay(NavigatorState navigator, dynamic route) {
    navigator.removeRoute(route);
  }
}
