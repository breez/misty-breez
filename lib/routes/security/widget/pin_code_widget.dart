import 'dart:math';

import 'package:l_breez/bloc/security/security_state.dart';
import 'package:l_breez/routes/security/widget/digit_masked_widget.dart';
import 'package:l_breez/routes/security/widget/num_pad_widget.dart';
import 'package:l_breez/widgets/preview/preview.dart';
import 'package:l_breez/widgets/shake_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PinCodeWidget extends StatefulWidget {
  final int pinLength;
  final String label;
  final LocalAuthenticationOption localAuthenticationOption;
  final Future<TestPinResult> Function(String pin) testPinCodeFunction;
  final Future<TestPinResult> Function()? testBiometricsFunction;

  const PinCodeWidget({
    super.key,
    this.pinLength = 6,
    required this.label,
    required this.testPinCodeFunction,
    this.testBiometricsFunction,
    this.localAuthenticationOption = LocalAuthenticationOption.none,
  });

  @override
  State<PinCodeWidget> createState() => _PinCodeWidgetState();
}

class _PinCodeWidgetState extends State<PinCodeWidget> with SingleTickerProviderStateMixin {
  String errorMessage = "";
  String pinCode = "";
  late ShakeController _digitsShakeController;

  @override
  void initState() {
    super.initState();
    _digitsShakeController = ShakeController(this);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            flex: 20,
            child: Center(
              child: SvgPicture.asset(
                "src/images/cloud-logo-color.svg",
                width: size.width / 3,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcATop,
                ),
              ),
            ),
          ),
          Flexible(
            flex: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(widget.label),
                ShakeWidget(
                  controller: _digitsShakeController,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.pinLength,
                      (index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DigitMaskedWidget(
                          filled: pinCode.length > index,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 50,
            child: NumPadWidget(
              lhsActionKey: ActionKey.Clear,
              rhsActionKey: pinCode.isNotEmpty
                  ? ActionKey.Backspace
                  : widget.localAuthenticationOption.isFacial
                      ? ActionKey.FaceId
                      : widget.localAuthenticationOption.isFingerprint ||
                              widget.localAuthenticationOption.isOtherBiometric
                          ? ActionKey.Fingerprint
                          : ActionKey.Backspace,
              onDigitPressed: (digit) {
                setState(() {
                  if (pinCode.length < widget.pinLength) {
                    pinCode += digit;
                    errorMessage = "";
                  }
                  if (pinCode.length == widget.pinLength) {
                    widget.testPinCodeFunction(pinCode).then((result) {
                      if (!result.success) {
                        setState(() {
                          errorMessage = result.errorMessage!;
                          pinCode = "";
                          _digitsShakeController.shake();
                        });
                      } else if (result.clearOnSuccess) {
                        setState(() {
                          pinCode = "";
                        });
                      }
                    });
                  }
                });
              },
              onActionKeyPressed: (action) {
                setState(() {
                  if (action == ActionKey.Clear) {
                    pinCode = "";
                    errorMessage = "";
                  } else if (action == ActionKey.Backspace && pinCode.isNotEmpty) {
                    pinCode = pinCode.substring(0, pinCode.length - 1);
                    errorMessage = "";
                  } else if (action == ActionKey.Fingerprint || action == ActionKey.FaceId) {
                    widget.testBiometricsFunction?.call().then((result) {
                      if (!result.success) {
                        pinCode = "";
                        errorMessage = result.errorMessage!;
                        _digitsShakeController.shake();
                      } else if (result.clearOnSuccess) {
                        pinCode = "";
                        errorMessage = "";
                      }
                    });
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TestPinResult {
  final bool success;
  final bool clearOnSuccess;
  final String? errorMessage;

  const TestPinResult(
    this.success, {
    this.clearOnSuccess = false,
    this.errorMessage,
  }) : assert(success || errorMessage != null, "errorMessage must be provided if success is false");
}

void main() {
  runApp(
    Preview(
      [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Small space, wrong pin code, face id:"),
        ),
        SizedBox(
          height: 280, // anything smaller than this will overflow some pixels
          child: PinCodeWidget(
            label: "First example",
            localAuthenticationOption: LocalAuthenticationOption.faceId,
            testPinCodeFunction: (pin) => SynchronousFuture(
              const TestPinResult(false, errorMessage: "Wrong pin code"),
            ),
            testBiometricsFunction: () => SynchronousFuture(
              const TestPinResult(false, errorMessage: "Wrong pin code"),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Medium space, correct pin code, fingerprint:"),
        ),
        SizedBox(
          height: 400,
          child: PinCodeWidget(
            label: "Second example",
            localAuthenticationOption: LocalAuthenticationOption.fingerprint,
            testPinCodeFunction: (pin) => SynchronousFuture(
              const TestPinResult(true),
            ),
            testBiometricsFunction: () => SynchronousFuture(
              const TestPinResult(true),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Large space, correct/incorrect randomly, no local auth:"),
        ),
        SizedBox(
          height: 600,
          child: PinCodeWidget(
            label: "Third example",
            localAuthenticationOption: LocalAuthenticationOption.none,
            testPinCodeFunction: (pin) async {
              return TestPinResult(Random().nextBool(), errorMessage: "A random error");
            },
            testBiometricsFunction: () async {
              return TestPinResult(Random().nextBool(), errorMessage: "A random error");
            },
          ),
        ),
      ],
    ),
  );
}
