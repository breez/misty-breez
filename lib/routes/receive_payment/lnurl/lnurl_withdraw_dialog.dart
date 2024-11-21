import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('LNURLWithdrawDialog');

class LnurlWithdrawDialog extends StatefulWidget {
  final Function(LNURLPageResult? result) onFinish;
  final LnUrlWithdrawRequestData requestData;
  final int amountSats;

  const LnurlWithdrawDialog({
    required this.requestData,
    required this.amountSats,
    required this.onFinish,
    super.key,
  });

  @override
  State<LnurlWithdrawDialog> createState() => _LnurlWithdrawDialogState();
}

class _LnurlWithdrawDialogState extends State<LnurlWithdrawDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  Future<LNURLPageResult>? _lnurlWithdrawFuture;
  bool finishCalled = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startWithdrawProcess();
  }

  void _setupAnimation() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..value = 1.0;
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.ease,
      ),
    );
  }

  void _startWithdrawProcess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _lnurlWithdrawFuture = _lnurlWithdraw().then(
          _processResultWithAnimation,
        );
      });
    });
  }

  FutureOr<LNURLPageResult> _processResultWithAnimation(LNURLPageResult result) {
    if (mounted && result.error == null) {
      _controller.addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.dismissed) {
          _onFinish(result);
        }
      });
      _controller.reverse();
    }
    return result;
  }

  @override
  void dispose() {
    if (!finishCalled) {
      _onFinish(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: themeData.colorScheme.surface,
      ),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog.fullscreen(
          child: FutureBuilder<LNURLPageResult>(
            future: _lnurlWithdrawFuture,
            builder: (BuildContext context, AsyncSnapshot<LNURLPageResult> snapshot) {
              final Object? snapshotError = snapshot.error ?? snapshot.data?.error;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Expanded(child: SizedBox.expand()),
                    Text(
                      texts.lnurl_withdraw_dialog_title,
                      style: themeData.dialogTheme.titleTextStyle,
                    ),
                    const SizedBox(height: 24),
                    if (snapshotError == null)
                      Column(
                        children: <Widget>[
                          LoadingAnimatedText(
                            loadingMessage: texts.lnurl_withdraw_dialog_wait,
                            textStyle: themeData.dialogTheme.contentTextStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Image.asset(
                            themeData.customData.loaderAssetPath,
                            gaplessPlayback: true,
                          ),
                        ],
                      )
                    else
                      ScrollableErrorMessageWidget(
                        title: texts.lnurl_withdraw_page_unknown_error_title,
                        message: extractExceptionMessage(snapshotError, texts),
                        padding: EdgeInsets.zero,
                      ),
                    const Expanded(child: SizedBox.expand()),
                    Theme(
                      data: breezDarkTheme,
                      child: SingleButtonBottomBar(
                        text: texts.lnurl_withdraw_dialog_action_close,
                        onPressed: () => _onFinish(null),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<LNURLPageResult> _lnurlWithdraw() async {
    final LnUrlCubit lnurlCubit = context.read<LnUrlCubit>();
    _logger.info(
      'LNURL withdraw of ${widget.amountSats} sats where '
      'min is ${widget.requestData.minWithdrawable.toInt() ~/ 1000} sats '
      'and max is ${widget.requestData.maxWithdrawable.toInt() ~/ 1000} sats.',
    );
    try {
      final LnUrlWithdrawRequest req = LnUrlWithdrawRequest(
        amountMsat: BigInt.from(widget.amountSats * 1000),
        data: widget.requestData,
        description: widget.requestData.defaultDescription,
      );
      final LnUrlWithdrawResult result = await lnurlCubit.lnurlWithdraw(req: req);
      return _handleLnUrlWithdrawResult(result);
    } catch (e) {
      _logger.warning('Error withdrawing LNURL payment', e);
      return LNURLPageResult(protocol: LnUrlProtocol.withdraw, error: e);
    }
  }

  LNURLPageResult _handleLnUrlWithdrawResult(LnUrlWithdrawResult result) {
    final BreezTranslations texts = context.texts();

    if (result is LnUrlWithdrawResult_Ok) {
      _logger.info('LNURL withdraw success for ${result.data.invoice.paymentHash}');
      return const LNURLPageResult(protocol: LnUrlProtocol.withdraw);
    } else if (result is LnUrlWithdrawResult_ErrorStatus) {
      _logger.warning('LNURL withdraw failed: ${result.data.reason}');
      return LNURLPageResult(protocol: LnUrlProtocol.withdraw, error: result.data.reason);
    } else {
      _logger.warning('Unknown response from lnurlWithdraw: $result');
      return LNURLPageResult(protocol: LnUrlProtocol.withdraw, error: texts.lnurl_payment_page_unknown_error);
    }
  }

  void _onFinish(LNURLPageResult? result) {
    if (finishCalled) {
      return;
    }
    setState(() {
      finishCalled = true;
    });
    _logger.info('Finishing with result $result');
    widget.onFinish(result);
  }
}