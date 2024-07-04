import 'package:l_breez/bloc/account/account_bloc.dart';
import 'package:l_breez/models/invoice.dart';
import 'package:l_breez/widgets/payment_dialogs/payment_confirmation_dialog.dart';
import 'package:l_breez/widgets/payment_dialogs/payment_request_info_dialog.dart';
import 'package:l_breez/widgets/payment_dialogs/processing_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PaymentRequestState {
  PAYMENT_REQUEST,
  WAITING_FOR_CONFIRMATION,
  PROCESSING_PAYMENT,
  USER_CANCELLED,
  PAYMENT_COMPLETED
}

class PaymentRequestDialog extends StatefulWidget {
  final Invoice invoice;
  final GlobalKey firstPaymentItemKey;

  const PaymentRequestDialog(
    this.invoice,
    this.firstPaymentItemKey, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return PaymentRequestDialogState();
  }
}

class PaymentRequestDialogState extends State<PaymentRequestDialog> {
  late AccountBloc accountBloc;
  PaymentRequestState? _state;
  String? _amountToPayStr;
  int? _amountToPay;

  ModalRoute? _currentRoute;

  @override
  void initState() {
    super.initState();
    accountBloc = context.read<AccountBloc>();
    _state = PaymentRequestState.PAYMENT_REQUEST;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentRoute ??= ModalRoute.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {
        if (_state == PaymentRequestState.PROCESSING_PAYMENT) {
          return;
        } else {
          final NavigatorState navigator = Navigator.of(context);
          accountBloc.cancelPayment(widget.invoice.bolt11);
          if (_currentRoute != null && _currentRoute!.isActive) {
            navigator.removeRoute(_currentRoute!);
          }
          return;
        }
      },
      child: showPaymentRequestDialog(),
    );
  }

  Widget showPaymentRequestDialog() {
    const double minHeight = 220;

    if (_state == PaymentRequestState.PROCESSING_PAYMENT) {
      return ProcessingPaymentDialog(
        firstPaymentItemKey: widget.firstPaymentItemKey,
        minHeight: minHeight,
        paymentFunc: () async {
          try {
            final prepareSendResponse = await accountBloc.prepareSendPayment(widget.invoice.bolt11);
            return await accountBloc.sendPayment(prepareSendResponse);
          } catch (e) {
            rethrow;
          }
        },
        onStateChange: (state) => _onStateChange(state),
      );
    } else if (_state == PaymentRequestState.WAITING_FOR_CONFIRMATION) {
      return PaymentConfirmationDialog(
        widget.invoice.bolt11,
        _amountToPay!,
        _amountToPayStr!,
        () => _onStateChange(PaymentRequestState.USER_CANCELLED),
        (bolt11, amount) => setState(() {
          _amountToPay = amount + widget.invoice.lspFee;
          _onStateChange(PaymentRequestState.PROCESSING_PAYMENT);
        }),
        minHeight,
      );
    } else {
      return PaymentRequestInfoDialog(
        widget.invoice,
        () => _onStateChange(PaymentRequestState.USER_CANCELLED),
        () => _onStateChange(PaymentRequestState.WAITING_FOR_CONFIRMATION),
        (bolt11, amount) {
          _amountToPay = amount + widget.invoice.lspFee;
          _onStateChange(PaymentRequestState.PROCESSING_PAYMENT);
        },
        (map) => _setAmountToPay(map),
        minHeight,
      );
    }
  }

  void _onStateChange(PaymentRequestState state) {
    if (state == PaymentRequestState.PAYMENT_COMPLETED) {
      Navigator.of(context).pop();
      return;
    }
    if (state == PaymentRequestState.USER_CANCELLED) {
      Navigator.of(context).pop();
      accountBloc.cancelPayment(widget.invoice.bolt11);
      return;
    }
    setState(() {
      _state = state;
    });
  }

  void _setAmountToPay(Map<String, dynamic> map) {
    _amountToPay = map["_amountToPay"] + widget.invoice.lspFee;
    _amountToPayStr = map["_amountToPayStr"];
  }
}
