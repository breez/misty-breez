import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/processing_payment/processing_payment_animated_content.dart';
import 'package:l_breez/widgets/processing_payment/processing_payment_content.dart';

const _kPaymentListItemHeight = 72.0;

class ProcessingPaymentDialog extends StatefulWidget {
  final GlobalKey? firstPaymentItemKey;
  final double minHeight;
  final bool popOnCompletion;
  final bool isLnUrlPayment;
  final Future Function() paymentFunc;

  const ProcessingPaymentDialog({
    this.firstPaymentItemKey,
    this.minHeight = 220,
    this.popOnCompletion = false,
    this.isLnUrlPayment = false,
    required this.paymentFunc,
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
  ModalRoute? _currentRoute;
  double? channelsSyncProgress;
  final Completer? synchronizedCompleter = Completer<bool>();

  @override
  void initState() {
    super.initState();
    _payAndClose();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    controller!.value = 1.0;
    controller!.addStatusListener((status) {
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
    var themeData = Theme.of(context);

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

  _payAndClose() {
    final navigator = Navigator.of(context);
    final texts = getSystemAppLocalizations();
    widget.paymentFunc().then((payResult) async {
      await _animateClose();
      if (widget.isLnUrlPayment) {
        navigator.pop(payResult);
      }
    }).catchError((err) {
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
        if (mounted) {
          showFlushbar(context, message: extractExceptionMessage(err, texts));
        }
      }
    });
  }

  Future _animateClose() {
    return Future.delayed(const Duration(milliseconds: 50)).then((_) {
      _initializeTransitionAnimation();
      setState(() {
        _animating = true;
        controller!.reverse();
      });
    });
  }

  void _initializeTransitionAnimation() {
    final queryData = MediaQuery.of(context);
    final statusBarHeight = queryData.padding.top;
    RenderBox? box = _dialogKey.currentContext!.findRenderObject() as RenderBox;
    startHeight = box.size.height;
    double yMargin = (queryData.size.height - box.size.height - 24) / 2;

    final endPosition = RelativeRect.fromLTRB(40.0, yMargin, 40.0, yMargin);
    RelativeRect startPosition = endPosition;
    final paymentCtx = widget.firstPaymentItemKey?.currentContext;
    if (paymentCtx != null) {
      RenderBox paymentTableBox = paymentCtx.findRenderObject() as RenderBox;
      final dy = paymentTableBox.localToGlobal(Offset.zero).dy;
      final start = dy - statusBarHeight;
      final end = queryData.size.height - start - _kPaymentListItemHeight;
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
            value: Theme.of(context).appBarTheme.systemOverlayStyle!.copyWith(
                  systemNavigationBarColor: Theme.of(context).colorScheme.surface,
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
