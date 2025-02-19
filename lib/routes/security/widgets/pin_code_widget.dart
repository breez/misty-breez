import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

class PinCodeWidget extends StatefulWidget {
  final int pinLength;
  final String label;
  final LocalAuthenticationOption localAuthenticationOption;
  final Future<TestPinResult> Function(String pin) testPinCodeFunction;
  final Future<TestPinResult> Function()? testBiometricsFunction;

  const PinCodeWidget({
    required this.label,
    required this.testPinCodeFunction,
    super.key,
    this.pinLength = 6,
    this.testBiometricsFunction,
    this.localAuthenticationOption = LocalAuthenticationOption.none,
  });

  @override
  State<PinCodeWidget> createState() => _PinCodeWidgetState();
}

class _PinCodeWidgetState extends State<PinCodeWidget> with SingleTickerProviderStateMixin {
  String errorMessage = '';
  String pinCode = '';
  late ShakeController _digitsShakeController;

  @override
  void initState() {
    super.initState();
    _digitsShakeController = ShakeController(this);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final ThemeData themeData = Theme.of(context);

    return SafeArea(
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 20,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/liquid-logo-color.svg',
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
              children: <Widget>[
                Text(widget.label),
                ShakeWidget(
                  controller: _digitsShakeController,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      widget.pinLength,
                      (int index) => Padding(
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
                  style: themeData.textTheme.headlineMedium?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 50,
            child: NumPadWidget(
              rhsActionKey: pinCode.isNotEmpty
                  ? ActionKey.backspace
                  : widget.localAuthenticationOption.isFacial
                      ? ActionKey.faceId
                      : widget.localAuthenticationOption.isFingerprint ||
                              widget.localAuthenticationOption.isOtherBiometric
                          ? ActionKey.fingerprint
                          : ActionKey.backspace,
              onDigitPressed: (String digit) {
                setState(() {
                  if (pinCode.length < widget.pinLength) {
                    pinCode += digit;
                    errorMessage = '';
                  }
                  if (pinCode.length == widget.pinLength) {
                    widget.testPinCodeFunction(pinCode).then((TestPinResult result) {
                      if (!result.success) {
                        setState(() {
                          errorMessage = result.errorMessage!;
                          pinCode = '';
                          _digitsShakeController.shake();
                        });
                      } else if (result.clearOnSuccess) {
                        setState(() {
                          pinCode = '';
                        });
                      }
                    });
                  }
                });
              },
              onActionKeyPressed: (ActionKey action) {
                setState(() {
                  if (action == ActionKey.clear) {
                    pinCode = '';
                    errorMessage = '';
                  } else if (action == ActionKey.backspace && pinCode.isNotEmpty) {
                    pinCode = pinCode.substring(0, pinCode.length - 1);
                    errorMessage = '';
                  } else if (action == ActionKey.fingerprint || action == ActionKey.faceId) {
                    widget.testBiometricsFunction?.call().then((TestPinResult result) {
                      if (!result.success) {
                        pinCode = '';
                        errorMessage = result.errorMessage!;
                        _digitsShakeController.shake();
                      } else if (result.clearOnSuccess) {
                        pinCode = '';
                        errorMessage = '';
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
  }) : assert(success || errorMessage != null, 'errorMessage must be provided if success is false');
}
