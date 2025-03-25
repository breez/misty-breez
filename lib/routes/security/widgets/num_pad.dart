import 'package:flutter/material.dart';
import 'package:misty_breez/routes/security/models/action_key.dart';
import 'package:misty_breez/routes/security/widgets/digit_button.dart';

/// A numeric keypad widget with digits 0-9 and action keys.
class NumPad extends StatelessWidget {
  /// The action key in the bottom-left position
  final ActionKey lhsActionKey;

  /// The action key in the bottom-right position
  final ActionKey rhsActionKey;

  /// Callback when a digit is pressed
  final Function(String?) onDigitPressed;

  /// Callback when an action key is pressed
  final Function(ActionKey) onActionKeyPressed;

  /// Creates a numeric keypad.
  ///
  /// [onDigitPressed] Callback when a digit button is pressed
  /// [onActionKeyPressed] Callback when an action key is pressed
  /// [lhsActionKey] The action key in the bottom-left position (default: clear)
  /// [rhsActionKey] The action key in the bottom-right position (default: backspace)
  const NumPad({
    required this.onDigitPressed,
    required this.onActionKeyPressed,
    super.key,
    this.lhsActionKey = ActionKey.clear,
    this.rhsActionKey = ActionKey.backspace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ..._buildDigitRows(),
        _buildBottomRow(),
      ],
    );
  }

  /// Builds the rows for digits 1-9
  List<Widget> _buildDigitRows() {
    return List<Widget>.generate(
      3,
      (int rowIndex) => Expanded(
        child: Row(
          children: List<Widget>.generate(
            3,
            (int colIndex) => Expanded(
              child: DigitButton(
                digit: '${colIndex + 1 + 3 * rowIndex}',
                onPressed: onDigitPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the bottom row with the left action key, digit 0, and right action key
  Widget _buildBottomRow() {
    return Expanded(
      child: Row(
        children: <Widget>[
          Expanded(
            child: DigitButton(
              icon: lhsActionKey.icon,
              onPressed: (_) => onActionKeyPressed(lhsActionKey),
            ),
          ),
          Expanded(
            child: DigitButton(
              digit: '0',
              onPressed: onDigitPressed,
            ),
          ),
          Expanded(
            child: DigitButton(
              icon: rhsActionKey.icon,
              onPressed: (_) => onActionKeyPressed(rhsActionKey),
            ),
          ),
        ],
      ),
    );
  }
}
