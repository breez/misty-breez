import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/security/widget/pin_code_widget.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SecuredPage');

class SecuredPage<T> extends StatefulWidget {
  final Widget securedWidget;

  const SecuredPage({required this.securedWidget, super.key});

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
          : BlocBuilder<SecurityCubit, SecurityState>(
              key: ValueKey<int>(DateTime.now().millisecondsSinceEpoch),
              builder: (BuildContext context, SecurityState state) {
                _logger.info('Building with: $state');
                if (state.pinStatus == PinStatus.enabled && !_allowed) {
                  final BreezTranslations texts = context.texts();
                  return Scaffold(
                    appBar: AppBar(
                      key: GlobalKey<ScaffoldState>(),
                    ),
                    body: PinCodeWidget(
                      label: texts.lock_screen_enter_pin,
                      testPinCodeFunction: (String pin) async {
                        _logger.info('Testing pin code');
                        bool pinMatches = false;
                        try {
                          final SecurityCubit securityCubit = context.read<SecurityCubit>();
                          pinMatches = await securityCubit.testPin(pin);
                        } catch (e) {
                          _logger.severe('Pin code test failed', e);
                          return TestPinResult(
                            false,
                            errorMessage: texts.lock_screen_pin_match_exception,
                          );
                        }
                        if (pinMatches) {
                          _logger.info('Pin matches');
                          setState(() {
                            _allowed = true;
                          });
                          return const TestPinResult(true);
                        } else {
                          _logger.info("Pin didn't match");
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
