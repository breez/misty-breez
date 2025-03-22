import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/security/models/auth_result.dart';
import 'package:misty_breez/routes/security/services/auth_service.dart';
import 'package:misty_breez/routes/security/widgets/pin_code.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SecuredPage');

/// A wrapper widget that requires PIN authentication before showing its content.
///
/// This widget provides an in-place authentication screen when security is enabled,
/// and transitions to the secured content upon successful authentication.
class SecuredPage<T> extends StatefulWidget {
  /// The widget to display after successful authentication
  final Widget securedWidget;

  /// Whether to attempt biometric authentication automatically
  final bool autoBiometrics;

  /// Creates a secured page
  ///
  /// [securedWidget] The widget to display after successful authentication
  /// [autoBiometrics] Whether to attempt biometric authentication automatically (default: true)
  const SecuredPage({
    required this.securedWidget,
    this.autoBiometrics = true,
    super.key,
  });

  @override
  State<SecuredPage<T>> createState() => _SecuredPageState<T>();
}

class _SecuredPageState<T> extends State<SecuredPage<T>> {
  /// Tracks if the user has been authenticated for this session
  bool _isAuthorized = false;

  /// Tracks if authentication is currently in progress
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _isAuthorized ? widget.securedWidget : _buildAuthenticationScreen(),
    );
  }

  /// Attempts automatic biometric authentication if available
  Future<void> _attemptBiometricAuth() async {
    if (_isAuthorized || _isAuthenticating) {
      return;
    }

    final AuthService authService = AuthService(context: context);

    // Only proceed if PIN is enabled and biometrics are available
    if (!authService.isPinEnabled || !authService.biometricType.isAvailable) {
      return;
    }

    _logger.info('Attempting automatic biometric authentication');

    // Authenticate without showing PIN screen first
    await _validateBiometrics();
  }

  /// Builds the authentication screen based on security state
  Widget _buildAuthenticationScreen() {
    final AuthService authService = AuthService(context: context);

    return BlocSelector<SecurityCubit, SecurityState, PinStatus>(
      selector: (SecurityState state) => state.pinStatus,
      builder: (BuildContext context, PinStatus pinStatus) {
        _logger.info('Security state updated: $pinStatus');

        // Skip authentication if PIN protection is not enabled
        if (!authService.isPinEnabled) {
          _logger.info('PIN protection not enabled, skipping authentication');
          Future<void>.delayed(Duration.zero, () => _setAuthorized());
          return widget.securedWidget;
        }

        return Scaffold(
          appBar: AppBar(),
          body: _buildPinAuthenticationScreen(),
        );
      },
    );
  }

  /// Builds the PIN authentication screen with biometric option if available
  Widget _buildPinAuthenticationScreen() {
    final AuthService authService = AuthService(context: context);

    return PinCode(
      label: context.texts().lock_screen_enter_pin,
      biometricType: authService.biometricType,
      validatePin: (String pin) => _validatePin(pin),
      validateBiometrics: () => _validateBiometrics(),
      logoAsset: 'assets/images/liquid-logo-color.svg',
    );
  }

  /// Validates the PIN code entered by the user
  ///
  /// [pin] The PIN code to validate
  ///
  /// Returns the result of PIN validation
  Future<AuthResult> _validatePin(String pin) async {
    if (_isAuthenticating) {
      return const AuthResult(success: false, errorMessage: 'Authentication in progress');
    }

    setState(() {
      _isAuthenticating = true;
    });

    _logger.info('Validating PIN');
    final AuthService authService = AuthService(context: context);

    try {
      final AuthResult result = await authService.validatePin(pin);

      if (!mounted) {
        return const AuthResult(success: false, errorMessage: 'Widget unmounted');
      }

      setState(() {
        _isAuthenticating = false;
      });

      if (result.success) {
        _logger.info('PIN validated successfully');
        _setAuthorized();
      }

      return result;
    } catch (e) {
      if (!mounted) {
        return const AuthResult(success: false, errorMessage: 'Widget unmounted');
      }

      setState(() {
        _isAuthenticating = false;
      });

      _logger.warning('PIN validation failed: $e');
      return AuthResult(
        success: false,
        errorMessage: context.texts().lock_screen_pin_match_exception,
      );
    }
  }

  /// Validates biometric authentication
  ///
  /// [context] The current build context
  ///
  /// Returns the result of biometric authentication
  Future<AuthResult> _validateBiometrics() async {
    final BreezTranslations texts = context.texts();

    if (_isAuthenticating) {
      return const AuthResult(success: false, errorMessage: 'Authentication in progress');
    }

    setState(() {
      _isAuthenticating = true;
    });

    final AuthService authService = AuthService(context: context);

    try {
      _logger.info('Attempting biometric authentication');
      final AuthResult result = await authService.authenticateWithBiometrics();

      if (!mounted) {
        return const AuthResult(success: false, errorMessage: 'Widget unmounted');
      }

      setState(() {
        _isAuthenticating = false;
      });

      if (result.success) {
        _logger.info('Biometric authentication succeeded');
        _setAuthorized();
      }

      return result;
    } catch (e) {
      if (!mounted) {
        return const AuthResult(success: false, errorMessage: 'Widget unmounted');
      }

      setState(() {
        _isAuthenticating = false;
      });

      _logger.severe('Biometric authentication error: $e');
      return AuthResult(
        success: false,
        errorMessage: texts.lock_screen_pin_match_exception,
      );
    }
  }

  /// Marks the user as authenticated and triggers a UI update
  void _setAuthorized() {
    if (!_isAuthorized) {
      setState(() => _isAuthorized = true);
      _logger.info('User authorized, showing secured content');
    }
  }
}
