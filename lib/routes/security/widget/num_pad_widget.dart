import 'package:flutter/material.dart';
import 'package:l_breez/routes/security/widget/digit_button_widget.dart';
import 'package:l_breez/widgets/preview/preview.dart';

class NumPadWidget extends StatelessWidget {
  final ActionKey lhsActionKey;
  final ActionKey rhsActionKey;
  final Function(String) onDigitPressed;
  final Function(ActionKey) onActionKeyPressed;

  const NumPadWidget({
    super.key,
    this.lhsActionKey = ActionKey.Clear,
    this.rhsActionKey = ActionKey.Backspace,
    required this.onDigitPressed,
    required this.onActionKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        ...List.generate(
          3,
          (r) => Expanded(
            child: Row(
              children: List.generate(
                3,
                (c) => Expanded(
                  child: DigitButtonWidget(
                    digit: "${c + 1 + 3 * r}",
                    onPressed: (digit) => onDigitPressed(digit!),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: DigitButtonWidget(
                  icon: lhsActionKey.icon,
                  onPressed: (_) => onActionKeyPressed(lhsActionKey),
                ),
              ),
              Expanded(
                child: DigitButtonWidget(
                  digit: "0",
                  onPressed: (digit) => onDigitPressed(digit!),
                ),
              ),
              Expanded(
                child: DigitButtonWidget(
                  icon: rhsActionKey.icon,
                  onPressed: (digit) => onActionKeyPressed(rhsActionKey),
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
  Fingerprint,
  FaceId,
  Backspace,
  Clear,
}

extension _ActionKeyIconExtension on ActionKey {
  IconData get icon {
    switch (this) {
      case ActionKey.Fingerprint:
        return Icons.fingerprint;
      case ActionKey.FaceId:
        return Icons.face;
      case ActionKey.Backspace:
        return Icons.backspace;
      case ActionKey.Clear:
        return Icons.delete_forever;
    }
  }
}

void main() {
  digitFun(digit) => debugPrint("Digit pressed: $digit");
  actionKeyFun(actionKey) => debugPrint("Action key pressed: $actionKey");

  runApp(
    Preview(
      [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Small space, default action key (backspace):"),
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
          child: Text("Medium space, FaceId action key:"),
        ),
        SizedBox(
          height: 400,
          child: NumPadWidget(
            rhsActionKey: ActionKey.FaceId,
            onDigitPressed: digitFun,
            onActionKeyPressed: actionKeyFun,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Large space, Fingerprint action key:"),
        ),
        SizedBox(
          height: 600,
          child: NumPadWidget(
            rhsActionKey: ActionKey.Fingerprint,
            onDigitPressed: digitFun,
            onActionKeyPressed: actionKeyFun,
          ),
        ),
      ],
    ),
  );
}
