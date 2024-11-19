import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/processing_payment/processing_payment_animated_content.dart';
import 'package:l_breez/widgets/processing_payment/processing_payment_content.dart';

const double _kPaymentListItemHeight = 72.0;

class ProcessingPaymentDialog extends StatefulWidget {
  final GlobalKey? firstPaymentItemKey;
  final double minHeight;
  final bool popOnCompletion;
  final bool isLnUrlPayment;
  final Future<dynamic> Function() paymentFunc;

  const ProcessingPaymentDialog({
    required this.paymentFunc,
    this.firstPaymentItemKey,
    this.minHeight = 220,
    this.popOnCompletion = false,
    this.isLnUrlPayment = false,
    super.key,
  });

  @override
  ProcessingPaymentDialogState createState() {
    return ProcessingPaymentDialogState();
  }
}

class ProcessingPaymentDialogState extends State<ProcessingPaymentDialog>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  bool _animating = false;
  double? startHeight;
  Animation<Color?>? colorAnimation;
  Animation<double>? borderAnimation;
  Animation<double>? opacityAnimation;
  Animation<RelativeRect>? transitionAnimation;
  final GlobalKey _dialogKey = GlobalKey();
  ModalRoute<dynamic>? _currentRoute;
  double? channelsSyncProgress;
  final Completer<bool>? synchronizedCompleter = Completer<bool>();

  @override
  void initState() {
    super.initState();
    _payAndClose();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    controller!.value = 1.0;
    controller!.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        if (widget.popOnCompletion) {
          Navigator.of(context).removeRoute(_currentRoute!);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData themeData = Theme.of(context);

    _currentRoute ??= ModalRoute.of(context);
    colorAnimation = ColorTween(
      begin: themeData.canvasColor,
      end: themeData.colorScheme.surface,
    ).animate(controller!)
      ..addListener(() {
        setState(() {});
      });
    borderAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: controller!, curve: Curves.ease),
    );
    opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller!, curve: Curves.ease),
    );
  }

  void _payAndClose() {
    final NavigatorState navigator = Navigator.of(context);
    widget.paymentFunc().then((dynamic payResult) async {
      await _animateClose();
      if (widget.isLnUrlPayment) {
        navigator.pop(payResult);
      }
    }).catchError((Object err) {
      if (widget.popOnCompletion) {
        navigator.removeRoute(_currentRoute!);
      }
      if (widget.isLnUrlPayment) {
        navigator.pop(err);
      }
      if (err is FrbException || err is PaymentError_PaymentTimeout) {
        if (_currentRoute != null && _currentRoute!.isActive) {
          navigator.removeRoute(_currentRoute!);
        }
        final BreezTranslations texts = getSystemAppLocalizations();
        final String message = extractExceptionMessage(err, texts);
        showFlushbar(context, message: texts.payment_error_to_send(message));
      }
    });
  }

  Future<void> _animateClose() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _initializeTransitionAnimation();
    setState(() {
      _animating = true;
      controller!.reverse();
    });
  }

  void _initializeTransitionAnimation() {
    final MediaQueryData queryData = MediaQuery.of(context);
    final double statusBarHeight = queryData.padding.top;
    final RenderBox box = _dialogKey.currentContext!.findRenderObject() as RenderBox;
    startHeight = box.size.height;
    final double yMargin = (queryData.size.height - box.size.height - 24) / 2;

    final RelativeRect endPosition = RelativeRect.fromLTRB(40.0, yMargin, 40.0, yMargin);
    RelativeRect startPosition = endPosition;
    final BuildContext? paymentCtx = widget.firstPaymentItemKey?.currentContext;
    if (paymentCtx != null) {
      final RenderBox paymentTableBox = paymentCtx.findRenderObject() as RenderBox;
      final double dy = paymentTableBox.localToGlobal(Offset.zero).dy;
      final double start = dy - statusBarHeight;
      final double end = queryData.size.height - start - _kPaymentListItemHeight;
      startPosition = RelativeRect.fromLTRB(0.0, start, 0.0, end);
    }
    transitionAnimation = RelativeRectTween(
      begin: startPosition,
      end: endPosition,
    ).animate(controller!);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return _animating
        ? ProcessingPaymentAnimatedContent(
            color: colorAnimation?.value ?? Colors.transparent,
            opacity: opacityAnimation!.value,
            moment: controller!.value,
            border: borderAnimation!.value,
            startHeight: startHeight ?? 0.0,
            transitionAnimation: transitionAnimation!,
            child: const ProcessingPaymentContent(),
          )
        : AnnotatedRegion<SystemUiOverlayStyle>(
            value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
              systemNavigationBarColor: themeData.colorScheme.surface,
            ),
            child: Dialog.fullscreen(
              child: Container(
                constraints: BoxConstraints(minHeight: widget.minHeight),
                child: Center(
                  child: ProcessingPaymentContent(dialogKey: _dialogKey),
                ),
              ),
            ),
          );
  }
}
