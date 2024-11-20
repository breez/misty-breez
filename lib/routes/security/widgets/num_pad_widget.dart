import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';

class NumPadWidget extends StatelessWidget {
  final ActionKey lhsActionKey;
  final ActionKey rhsActionKey;
  final Function(String) onDigitPressed;
  final Function(ActionKey) onActionKeyPressed;

  const NumPadWidget({
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
        ...List<Widget>.generate(
          3,
          (int r) => Expanded(
            child: Row(
              children: List<Widget>.generate(
                3,
                (int c) => Expanded(
                  child: DigitButtonWidget(
                    digit: '${c + 1 + 3 * r}',
                    onPressed: (String? digit) => onDigitPressed(digit!),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: DigitButtonWidget(
                  icon: lhsActionKey.icon,
                  onPressed: (_) => onActionKeyPressed(lhsActionKey),
                ),
              ),
              Expanded(
                child: DigitButtonWidget(
                  digit: '0',
                  onPressed: (String? digit) => onDigitPressed(digit!),
                ),
              ),
              Expanded(
                child: DigitButtonWidget(
                  icon: rhsActionKey.icon,
                  onPressed: (String? digit) => onActionKeyPressed(rhsActionKey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum ActionKey {
  fingerprint,
  faceId,
  backspace,
  clear,
}

extension _ActionKeyIconExtension on ActionKey {
  IconData get icon {
    switch (this) {
      case ActionKey.fingerprint:
        return Icons.fingerprint;
      case ActionKey.faceId:
        return Icons.face;
      case ActionKey.backspace:
        return Icons.backspace;
      case ActionKey.clear:
        return Icons.delete_forever;
    }
  }
}
