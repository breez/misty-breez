import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/invoice.dart';
import 'package:l_breez/widgets/payment_dialogs/payment_confirmation_dialog.dart';
import 'package:l_breez/widgets/payment_dialogs/payment_request_info_dialog.dart';
import 'package:l_breez/widgets/payment_dialogs/processing_payment_dialog.dart';
import 'package:service_injector/service_injector.dart';

enum PaymentRequestState {
  paymentRequest,
  waitingForConfirmation,
  processingPayment,
  userCancelled,
  paymentCompleted
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
  late PaymentsCubit paymentsCubit;
  PaymentRequestState? _state;
  String? _amountToPayStr;
  int? _amountToPay;

  ModalRoute? _currentRoute;

  @override
  void initState() {
    super.initState();
    paymentsCubit = context.read<PaymentsCubit>();
    _state = PaymentRequestState.paymentRequest;
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
        if (_state == PaymentRequestState.processingPayment) {
          return;
        } else {
          final NavigatorState navigator = Navigator.of(context);
          paymentsCubit.cancelPayment(widget.invoice.bolt11);
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

    if (_state == PaymentRequestState.processingPayment) {
      return ProcessingPaymentDialog(
        firstPaymentItemKey: widget.firstPaymentItemKey,
        minHeight: minHeight,
        paymentFunc: () async {
          try {
            final prepareSendResponse = await paymentsCubit.prepareSendPayment(widget.invoice.bolt11);
            return await paymentsCubit.sendPayment(prepareSendResponse);
          } catch (e) {
            rethrow;
          }
        },
        onStateChange: (state) => _onStateChange(state),
      );
    } else if (_state == PaymentRequestState.waitingForConfirmation) {
      return PaymentConfirmationDialog(
        widget.invoice.bolt11,
        _amountToPay!,
        _amountToPayStr!,
        () => _onStateChange(PaymentRequestState.userCancelled),
        (bolt11, amount) => setState(() {
          _amountToPay = amount + widget.invoice.lspFee;
          _onStateChange(PaymentRequestState.processingPayment);
        }),
        minHeight,
      );
    } else {
      return BlocProvider(
        create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().liquidSDK),
        child: PaymentRequestInfoDialog(
          widget.invoice,
          (message) => _onStateChange(PaymentRequestState.userCancelled, message: message),
          () => _onStateChange(PaymentRequestState.waitingForConfirmation),
          (bolt11, amount) {
            _amountToPay = amount + widget.invoice.lspFee;
            _onStateChange(PaymentRequestState.processingPayment);
          },
          (map) => _setAmountToPay(map),
          minHeight,
        ),
      );
    }
  }

  void _onStateChange(
    PaymentRequestState state, {
    String? message,
  }) {
    if (state == PaymentRequestState.paymentCompleted) {
      Navigator.of(context).pop();
      return;
    }
    if (state == PaymentRequestState.userCancelled) {
      Navigator.of(context).pop(message);
      paymentsCubit.cancelPayment(widget.invoice.bolt11);
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
