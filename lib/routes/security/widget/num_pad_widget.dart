import 'package:flutter/material.dart';
import 'package:l_breez/routes/security/widget/digit_button_widget.dart';
import 'package:l_breez/widgets/preview/preview.dart';

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

void main() {
  void digitFun(String digit) => debugPrint('Digit pressed: $digit');
  void actionKeyFun(ActionKey actionKey) => debugPrint('Action key pressed: $actionKey');

  runApp(
    Preview(
      <Widget>[
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Small space, default action key (backspace):'),
        ),
        SizedBox(
          height: 200,
          child: NumPadWidget(
            onDigitPressed: digitFun,
            onActionKeyPressed: actionKeyFun,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Medium space, FaceId action key:'),
        ),
        SizedBox(
          height: 400,
          child: NumPadWidget(
            rhsActionKey: ActionKey.faceId,
            onDigitPressed: digitFun,
            onActionKeyPressed: actionKeyFun,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Large space, Fingerprint action key:'),
        ),
        SizedBox(
          height: 600,
          child: NumPadWidget(
            rhsActionKey: ActionKey.fingerprint,
            onDigitPressed: digitFun,
            onActionKeyPressed: actionKeyFun,
          ),
        ),
      ],
    ),
  );
}
