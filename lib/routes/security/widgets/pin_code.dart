import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';

final Logger _logger = Logger('PinCodeWidget');

/// Widget for PIN code input and validation
class PinCode extends StatefulWidget {
  /// Length of the PIN code
  final int pinLength;

  /// Label text displayed above the PIN input
  final String label;

  /// Type of biometric authentication available
  final BiometricType biometricType;

  /// Function to validate the entered PIN code
  final Future<AuthResult> Function(String pin) validatePin;

  /// Function to perform biometric authentication
  final Future<AuthResult> Function()? validateBiometrics;

  /// Logo asset path
  final String? logoAsset;

  /// Creates a PIN code input widget
  ///
  /// [label] Text displayed above the PIN digits
  /// [validatePin] Function to validate the PIN
  /// [pinLength] Number of digits in the PIN (default: 6)
  /// [validateBiometrics] Optional function for biometric authentication
  /// [biometricType] Type of biometric authentication available (default: none)
  /// [logoAsset] Optional logo asset path to display above the PIN
  const PinCode({
    required this.label,
    required this.validatePin,
    super.key,
    this.pinLength = 6,
    this.validateBiometrics,
    this.biometricType = BiometricType.none,
    this.logoAsset,
  });

  @override
  State<PinCode> createState() => _PinCodeState();
}

class _PinCodeState extends State<PinCode> with SingleTickerProviderStateMixin {
  /// Error message to display below the PIN code
  String _errorMessage = '';

  /// Currently entered PIN code
  String _pinCode = '';

  /// Controller for the shake animation on error
  late ShakeController _digitsShakeController;

  /// Whether a PIN validation is in progress
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _digitsShakeController = ShakeController(vsync: this);
    _logger.fine('PinCode initialized with biometric type: ${widget.biometricType}');
  }

  @override
  void dispose() {
    _digitsShakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 20,
            child: Center(
              child: _buildLogo(size),
            ),
          ),
          Flexible(
            flex: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(widget.label),
                _buildPinDigitsDisplay(),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: themeData.textTheme.headlineMedium?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 50,
            child: NumPad(
              rhsActionKey: _determineRightActionKey(),
              onDigitPressed: _handleDigitPress,
              onActionKeyPressed: _handleActionKeyPress,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the logo if provided
  Widget _buildLogo(Size size) {
    if (widget.logoAsset == null) {
      return const SizedBox.shrink();
    }

    // Handle SVG or regular assets
    if (widget.logoAsset!.endsWith('.svg')) {
      return SvgPicture.asset(
        widget.logoAsset!,
        width: size.width / 3,
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcATop,
        ),
      );
    }

    return Image.asset(
      widget.logoAsset!,
      width: size.width / 3,
    );
  }

  /// Builds the masked PIN digits display
  Widget _buildPinDigitsDisplay() {
    return ShakeWidget(
      controller: _digitsShakeController,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(
          widget.pinLength,
          (int index) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: DigitMasked(
              filled: _pinCode.length > index,
            ),
          ),
        ),
      ),
    );
  }

  /// Determines which action key to show on the right side of the keypad
  ActionKey _determineRightActionKey() {
    if (_pinCode.isNotEmpty) {
      return ActionKey.backspace;
    } else if (widget.biometricType.isFacial) {
      return ActionKey.faceId;
    } else if (widget.biometricType.isFingerprint || widget.biometricType.isOtherBiometric) {
      return ActionKey.fingerprint;
    } else {
      return ActionKey.backspace;
    }
  }

  /// Handles digit button presses
  void _handleDigitPress(String? digit) {
    if (_isValidating) {
      return;
    }
    if (digit == null) {
      return;
    }

    setState(() {
      if (_pinCode.length < widget.pinLength) {
        _pinCode += digit;
        _errorMessage = '';
      }

      if (_pinCode.length == widget.pinLength) {
        _validatePin();
      }
    });
  }

  /// Validates the entered PIN code
  Future<void> _validatePin() async {
    if (_isValidating) {
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      _logger.fine('Validating PIN code');
      final AuthResult result = await widget.validatePin(_pinCode);

      if (!mounted) {
        return;
      }

      setState(() {
        if (!result.success) {
          _errorMessage = result.errorMessage!;
          _pinCode = '';
          _digitsShakeController.shake();
          _logger.warning('PIN validation failed: $_errorMessage');
        } else if (result.clearOnSuccess) {
          _pinCode = '';
          _logger.fine('PIN validated successfully and cleared');
        } else {
          _logger.fine('PIN validated successfully');
        }
        _isValidating = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Authentication error';
        _pinCode = '';
        _isValidating = false;
        _logger.severe('Error during PIN validation: $e');
      });
    }
  }

  /// Handles action key (backspace, clear, biometric) presses
  void _handleActionKeyPress(ActionKey action) async {
    if (_isValidating) {
      return;
    }

    if (action == ActionKey.clear) {
      setState(() {
        _pinCode = '';
        _errorMessage = '';
      });
    } else if (action == ActionKey.backspace && _pinCode.isNotEmpty) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
        _errorMessage = '';
      });
    } else if ((action == ActionKey.fingerprint || action == ActionKey.faceId) &&
        widget.validateBiometrics != null) {
      _authenticateWithBiometrics();
    }
  }

  /// Attempts biometric authentication
  Future<void> _authenticateWithBiometrics() async {
    if (_isValidating) {
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      _logger.fine('Attempting biometric authentication');
      final AuthResult result = await widget.validateBiometrics!();

      if (!mounted) {
        return;
      }

      setState(() {
        if (!result.success) {
          _pinCode = '';
          _errorMessage = result.errorMessage!;
          _digitsShakeController.shake();
          _logger.warning('Biometric authentication failed: $_errorMessage');
        } else if (result.clearOnSuccess) {
          _pinCode = '';
          _errorMessage = '';
          _logger.fine('Biometric authentication succeeded');
        }
        _isValidating = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Biometric error';
        _pinCode = '';
        _isValidating = false;
        _logger.severe('Error during biometric authentication: $e');
      });
    }
  }
}
