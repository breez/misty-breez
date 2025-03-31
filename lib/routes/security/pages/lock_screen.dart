import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';

final Logger _logger = Logger('LockScreen');

/// A screen that requires authentication before allowing access.
///
/// This screen handles PIN code and biometric authentication based on user preferences.
class LockScreen extends StatefulWidget {
  /// Route name for navigation
  static const String routeName = 'lockscreen';

  /// The action to perform after successful authentication
  final AuthorizedAction authorizedAction;

  /// Whether to attempt biometric authentication automatically
  final bool autoBiometrics;

  /// Creates a lock screen
  ///
  /// [authorizedAction] The action to perform after successful authentication
  /// [autoBiometrics] Whether to attempt biometric authentication automatically (default: true)
  const LockScreen({
    required this.authorizedAction,
    this.autoBiometrics = true,
    super.key,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Allow the widget to fully build before attempting biometric auth
    if (widget.autoBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptBiometricAuth();
      });
    }
  }

  /// Attempts biometric authentication automatically if available and enabled
  Future<void> _attemptBiometricAuth() async {
    if (_isAuthenticating) {
      return;
    }

    final AuthService authService = AuthService(context: context);

    // Only proceed if PIN is enabled and biometrics are available
    if (!authService.isPinEnabled || !authService.biometricType.isAvailable) {
      _logger.info('${authService.isPinEnabled} & ${authService.biometricType.isAvailable}');
      return;
    }

    _logger.info('Attempting biometric authentication');

    // Attempt to authenticate with biometrics before showing PIN screen
    await _validateBiometrics(context);
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(context: context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: BlocSelector<SecurityCubit, SecurityState, PinStatus>(
          selector: (SecurityState state) => state.pinStatus,
          builder: (BuildContext context, PinStatus pinStatus) {
            if (!authService.isPinEnabled) {
              _logger.info('PIN protection not enabled, skipping authentication');
              _executeAuthorizedAction(Navigator.of(context));
              return const SizedBox.shrink();
            }

            return _buildAuthenticationScreen(context);
          },
        ),
      ),
    );
  }

  /// Builds the authentication screen with PIN and/or biometric options
  Widget _buildAuthenticationScreen(BuildContext context) {
    final AuthService authService = AuthService(context: context);

    return PinCode(
      label: context.texts().lock_screen_enter_pin,
      biometricType: authService.biometricType,
      validatePin: (String pin) => _validatePin(context, pin),
      validateBiometrics: () => _validateBiometrics(context),
      logoAsset: 'assets/images/breez-logo.svg',
    );
  }

  /// Validates the PIN code entered by the user
  ///
  /// [context] The current build context
  /// [pin] The PIN code to validate
  ///
  /// Returns the result of PIN validation
  Future<AuthResult> _validatePin(
    BuildContext context,
    String pin,
  ) async {
    if (_isAuthenticating) {
      return const AuthResult(success: false, errorMessage: 'Authentication in progress');
    }

    setState(() => _isAuthenticating = true);

    _logger.info('Validating PIN');
    final BreezTranslations texts = context.texts();
    final NavigatorState navigatorState = Navigator.of(context);
    final AuthService authService = AuthService(context: context);

    try {
      final AuthResult result = await authService.validatePin(pin);

      if (result.success && context.mounted) {
        _logger.info('PIN validated successfully');
        _executeAuthorizedAction(navigatorState);
      }

      return result;
    } catch (e) {
      _logger.severe('PIN validation error: $e');
      return AuthResult(
        success: false,
        errorMessage: texts.lock_screen_pin_match_exception,
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  /// Validates biometric authentication
  ///
  /// [context] The current build context
  ///
  /// Returns the result of biometric authentication
  Future<AuthResult> _validateBiometrics(BuildContext context) async {
    if (_isAuthenticating && mounted) {
      return const AuthResult(success: false, errorMessage: 'Authentication in progress');
    }

    if (mounted) {
      setState(() => _isAuthenticating = true);
    }

    final BreezTranslations texts = context.texts();
    final NavigatorState navigatorState = Navigator.of(context);
    final AuthService authService = AuthService(context: context);

    try {
      final AuthResult result = await authService.authenticateWithBiometrics();

      if (result.success && context.mounted) {
        _logger.info('Biometric authentication succeeded');
        _executeAuthorizedAction(navigatorState);
      }

      return result;
    } catch (e) {
      _logger.severe('Biometric authentication error: $e');
      return AuthResult(
        success: false,
        errorMessage: texts.lock_screen_pin_match_exception,
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  /// Executes the appropriate action after successful authentication
  ///
  /// [navigator] The navigator to use for navigation
  void _executeAuthorizedAction(NavigatorState navigator) {
    _logger.info('Executing authorized action: ${widget.authorizedAction}');
    switch (widget.authorizedAction) {
      case AuthorizedAction.launchHome:
        navigator.pushReplacementNamed(Home.routeName);
      case AuthorizedAction.popPage:
        navigator.pop(true);
    }
  }
}
