import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/address_header_widget.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/address_qr_widget.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/transparent_page_route.dart';
import 'package:logging/logging.dart';

enum AddressWidgetType { lightning, bitcoin }

final _log = Logger("AddressWidget");

class AddressWidget extends StatefulWidget {
  final String? address;
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? footer;
  final String? title;
  final void Function()? onLongPress;
  final AddressWidgetType type;
  final Widget? infoWidget;

  const AddressWidget({
    this.snapshot,
    super.key,
    this.footer,
    this.title,
    this.onLongPress,
    this.type = AddressWidgetType.lightning,
    this.infoWidget,
    this.address,
  });

  @override
  State<AddressWidget> createState() => _AddressWidgetState();
}

class _AddressWidgetState extends State<AddressWidget> {
  @override
  void didUpdateWidget(covariant AddressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    String? destination = _getDestination(oldWidget);
    _trackPayment(destination);
  }

  String? _getDestination(AddressWidget oldWidget) {
    String? destination;
    if (widget.address != null) {
      if (widget.address != oldWidget.address) {
        destination = widget.address!;
      }
    } else if ((widget.snapshot != null && widget.snapshot!.hasData) &&
        (oldWidget.snapshot != null && oldWidget.snapshot!.hasData)) {
      if (widget.snapshot!.data!.destination != oldWidget.snapshot!.data!.destination) {
        destination = widget.snapshot!.data!.destination;
      }
    }
    return destination;
  }

  void _trackPayment(String? destination) {
    final inputCubit = context.read<InputCubit>();
    inputCubit.trackPayment(destination).then((value) {
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _onPaymentFinished(true);
        }
      });
    }).catchError((e) {
      _log.warning("Failed to track payment", e);
      if (mounted) {
        showFlushbar(context, message: extractExceptionMessage(e, context.texts()));
      }
      _onPaymentFinished(false);
    });
  }

  void _onPaymentFinished(dynamic result) {
    _log.info("Payment finished: $result");
    if (result == true) {
      if (mounted) {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(TransparentPageRoute((ctx) => const SuccessfulPaymentRoute()));
      }
    } else {
      if (result is String) {
        showFlushbar(context, title: "", message: result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: AddressHeaderWidget(
            snapshot: widget.snapshot,
            address: widget.address,
            title: widget.title,
            type: widget.type,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AddressQRWidget(
            address: widget.address,
            snapshot: widget.snapshot,
            infoWidget: widget.infoWidget,
            footer: widget.footer,
            onLongPress: widget.onLongPress,
            type: widget.type,
          ),
        ),
      ],
    );
  }
}
