// ignore_for_file: use_key_in_widget_constructors

import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/bloc/input/input_bloc.dart';
import 'package:l_breez/bloc/input/input_state.dart';
import 'package:l_breez/routes/create_invoice/widgets/expiry_and_fee_message.dart';
import 'package:l_breez/routes/create_invoice/widgets/invoice_qr.dart';
import 'package:l_breez/routes/create_invoice/widgets/loading_or_error.dart';
import 'package:l_breez/services/injector.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger("QrCodeDialog");

class QrCodeDialog extends StatefulWidget {
  final PrepareReceiveResponse prepareReceiveResponse;
  final ReceivePaymentResponse? receivePaymentResponse;
  final Object? error;
  final Function(dynamic result) _onFinish;

  const QrCodeDialog(
    this.prepareReceiveResponse,
    this.receivePaymentResponse,
    this.error,
    this._onFinish,
  );

  @override
  State<StatefulWidget> createState() {
    return QrCodeDialogState();
  }
}

class QrCodeDialogState extends State<QrCodeDialog> with SingleTickerProviderStateMixin {
  Animation<double>? _opacityAnimation;
  ModalRoute? _currentRoute;
  AnimationController? _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller!, curve: Curves.ease));
    _controller!.value = 1.0;
    _controller!.addStatusListener((status) async {
      if (status == AnimationStatus.dismissed && mounted) {
        onFinish(true);
      }
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute ??= ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(covariant QrCodeDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.receivePaymentResponse?.id != oldWidget.receivePaymentResponse?.id) {
      context.read<InputBloc>().trackPayment(widget.receivePaymentResponse!.id).then((value) {
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _controller!.reverse();
          }
        });
      }).catchError((e) {
        _log.warning("Failed to track payment", e);
        showFlushbar(context, message: extractExceptionMessage(e, context.texts()));
        onFinish(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final error = widget.error;

    return BlocBuilder<InputBloc, InputState>(
      builder: (context, inputState) {
        return FadeTransition(
          opacity: _opacityAnimation!,
          child: SimpleDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(texts.qr_code_dialog_invoice),
                Row(
                  children: <Widget>[
                    Tooltip(
                      message: texts.qr_code_dialog_share,
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 2.0, left: 14.0),
                        icon: const Icon(IconData(0xe917, fontFamily: 'icomoon')),
                        color: themeData.primaryTextTheme.labelLarge!.color!,
                        onPressed: () {
                          Share.share(widget.receivePaymentResponse!.invoice);
                        },
                      ),
                    ),
                    Tooltip(
                      message: texts.qr_code_dialog_copy,
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 14.0, left: 2.0),
                        icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon')),
                        color: themeData.primaryTextTheme.labelLarge!.color!,
                        onPressed: () {
                          ServiceInjector().device.setClipboardText(widget.receivePaymentResponse!.invoice);
                          showFlushbar(
                            context,
                            message: texts.qr_code_dialog_copied,
                            duration: const Duration(seconds: 3),
                          );
                        },
                      ),
                    )
                  ],
                )
              ],
            ),
            titlePadding: const EdgeInsets.fromLTRB(20.0, 22.0, 0.0, 8.0),
            contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0, bottom: 20.0),
            children: <Widget>[
              AnimatedCrossFade(
                firstChild: LoadingOrError(
                  error: error,
                  displayErrorMessage: error != null
                      ? extractExceptionMessage(error, texts)
                      : texts.qr_code_dialog_warning_message_error,
                ),
                secondChild: widget.receivePaymentResponse == null
                    ? const SizedBox()
                    : Column(
                        children: [
                          InvoiceQR(bolt11: widget.receivePaymentResponse!.invoice),
                          const Padding(padding: EdgeInsets.only(top: 16.0)),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: ExpiryAndFeeMessage(feesSat: widget.prepareReceiveResponse.feesSat.toInt()),
                          ),
                          const Padding(padding: EdgeInsets.only(top: 16.0)),
                        ],
                      ),
                duration: const Duration(seconds: 1),
                crossFadeState: widget.receivePaymentResponse == null
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
              ),
              TextButton(
                onPressed: (() {
                  onFinish(false);
                }),
                child: Text(
                  texts.qr_code_dialog_action_close,
                  style: themeData.primaryTextTheme.labelLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void onFinish(dynamic result) {
    _log.info("onFinish $result, mounted: $mounted, _currentRoute: ${_currentRoute?.isCurrent}");
    if (mounted && _currentRoute != null && _currentRoute!.isCurrent) {
      Navigator.removeRoute(context, _currentRoute!);
    }
    widget._onFinish(result);
  }
}
