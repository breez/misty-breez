import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/bloc/security/security_bloc.dart';
import 'package:l_breez/bloc/security/security_state.dart';
import 'package:l_breez/routes/security/widget/pin_code_widget.dart';
import 'package:logging/logging.dart';

final _log = Logger("SecuredPage");

class SecuredPage<T> extends StatefulWidget {
  final Widget securedWidget;

  const SecuredPage({
    super.key,
    required this.securedWidget,
  });

  @override
  State<SecuredPage<T>> createState() => _SecuredPageState<T>();
}

class _SecuredPageState<T> extends State<SecuredPage<T>> {
  bool _allowed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _allowed
          ? widget.securedWidget
          : BlocBuilder<SecurityBloc, SecurityState>(
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              builder: (context, state) {
                _log.info("Building with: $state");
                if (state.pinStatus == PinStatus.enabled && !_allowed) {
                  final texts = context.texts();
                  return Scaffold(
                    appBar: AppBar(
                      key: GlobalKey<ScaffoldState>(),
                    ),
                    body: PinCodeWidget(
                      label: texts.lock_screen_enter_pin,
                      testPinCodeFunction: (pin) async {
                        _log.info("Testing pin code");
                        bool pinMatches = false;
                        try {
                          pinMatches = await context.read<SecurityBloc>().testPin(pin);
                        } catch (e) {
                          _log.severe("Pin code test failed", e);
                          return TestPinResult(
                            false,
                            errorMessage: texts.lock_screen_pin_match_exception,
                          );
                        }
                        if (pinMatches) {
                          _log.info("Pin matches");
                          setState(() {
                            _allowed = true;
                          });
                          return const TestPinResult(true);
                        } else {
                          _log.info("Pin didn't match");
                          return TestPinResult(
                            false,
                            errorMessage: texts.lock_screen_pin_incorrect,
                          );
                        }
                      },
                    ),
                  );
                } else {
                  _allowed = true;
                  return widget.securedWidget;
                }
              },
            ),
    );
  }
}
