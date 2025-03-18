import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/security/models/auth_result.dart';
import 'package:l_breez/routes/security/services/auth_service.dart';
import 'package:l_breez/routes/security/widgets/pin_code.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:logging/logging.dart';

final Logger _logger = Logger('ChangePinPage');

/// Possible states during PIN creation/change flow
enum _PinEntryState {
  /// First PIN entry
  initial,

  /// Confirming PIN with second entry
  confirming,
}

/// A page for creating or changing the PIN code
class ChangePinPage extends StatefulWidget {
  /// Creates a change PIN page
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  /// First PIN entry for confirmation
  String _firstPinCode = '';

  /// Current state in the PIN entry flow
  _PinEntryState _currentState = _PinEntryState.initial;

  /// Whether a PIN update is in progress
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _logger.info('Change PIN page initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
      ),
      body: PinCode(
        label: _getLabelText(),
        validatePin: (String pin) => _handlePinEntry(pin),
        logoAsset: 'assets/images/liquid-logo-color.svg',
      ),
    );
  }

  /// Gets the appropriate label text based on the current state
  String _getLabelText() {
    final BreezTranslations texts = context.texts();

    return _currentState == _PinEntryState.initial
        ? texts.security_and_backup_new_pin
        : texts.security_and_backup_new_pin_second_time;
  }

  /// Handles PIN entry based on the current flow state
  Future<AuthResult> _handlePinEntry(String pin) async {
    if (_isProcessing) {
      return const AuthResult(success: false, errorMessage: 'Processing, please wait');
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_currentState == _PinEntryState.initial) {
        return _handleFirstPinEntry(pin);
      } else {
        return await _handlePinConfirmation(pin);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Handles the first PIN entry
  AuthResult _handleFirstPinEntry(String pin) {
    _logger.info('First PIN entered');
    setState(() {
      _firstPinCode = pin;
      _currentState = _PinEntryState.confirming;
    });
    return const AuthResult(success: true, clearOnSuccess: true);
  }

  /// Handles the PIN confirmation entry
  Future<AuthResult> _handlePinConfirmation(String pin) async {
    final BreezTranslations texts = context.texts();

    if (pin != _firstPinCode) {
      _logger.warning('PIN confirmation failed - PINs do not match');
      setState(() {
        _firstPinCode = '';
        _currentState = _PinEntryState.initial;
      });
      return AuthResult(
        success: false,
        errorMessage: texts.security_and_backup_new_pin_do_not_match,
      );
    }

    try {
      _logger.info('PIN confirmed, saving new PIN');
      final AuthService authService = AuthService(context: context);
      final bool success = await authService.createOrUpdatePin(pin);

      if (!mounted) {
        return const AuthResult(success: true);
      }

      if (success) {
        _logger.info('PIN successfully updated, returning to previous screen');
        Navigator.of(context).pop();
        return const AuthResult(success: true);
      } else {
        // texts.security_and_backup_error_saving_pin,
        return const AuthResult(
          success: false,
          errorMessage: 'Failed to save PIN.',
        );
      }
    } catch (e) {
      _logger.severe('Error saving PIN: $e');
      return AuthResult(
        success: false,
        errorMessage: 'Failed to save PIN: $e',
      );
    }
  }
}
