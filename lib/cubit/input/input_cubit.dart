library input_bloc;

import 'dart:async';

import 'package:device_client/device_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/invoice.dart';
import 'package:l_breez/models/payment_details_extension.dart';
import 'package:lightning_links/lightning_links.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:service_injector/service_injector.dart';

export 'input_state.dart';

final _log = Logger("InputCubit");

class InputCubit extends Cubit<InputState> {
  final LightningLinksService _lightningLinks;
  final DeviceClient _deviceClient;

  final _decodeInvoiceController = StreamController<InputData>();

  InputCubit(
    this._lightningLinks,
    this._deviceClient,
  ) : super(const InputState.empty()) {
    _initializeInputCubit();
  }

  void _initializeInputCubit() async {
    _log.info("initializeInputCubit");
    _watchIncomingInvoices().listen((inputState) => emit(inputState!));
  }

  void addIncomingInput(String input, InputSource source) {
    _log.info("addIncomingInput: $input source: $source");
    _decodeInvoiceController.add(InputData(data: input, source: source));
  }

  Future trackPayment(String? trackedPaymentId) async {
    _log.info("Tracking incoming payment: $trackedPaymentId");
    await ServiceInjector().liquidSDK.paymentResultStream.firstWhere(
      (payment) {
        if (trackedPaymentId != null && trackedPaymentId.isNotEmpty) {
          // TODO: Question: Which payment details fields correlate to  ReceivePaymentResponse.destination?
          // Does PaymentDetails_Lightning.bolt11 correlate to ReceivePaymentResponse.destination?
          // Does PaymentDetails_Bitcoin.swapId correlate to ReceivePaymentResponse.destination?
          final receivedPaymentId = payment.details?.maybeMap(
                bitcoin: (details) => details.swapId,
                lightning: (details) => details.bolt11,
                // TODO: liquid: is unused as Liquid payments are not integrated yet
                liquid: (details) => details.destination,
                orElse: () => "",
              ) ??
              "";
          if (receivedPaymentId.isNotEmpty) {
            if (receivedPaymentId == trackedPaymentId &&
                (payment.status == PaymentState.pending || payment.status == PaymentState.complete)) {
              _log.info("Payment Received! Id: $trackedPaymentId");
              return true;
            }
          }
        }
        return false;
      },
    );
  }

  Stream<InputState?> _watchIncomingInvoices() {
    _log.info("watchIncomingInvoices");
    return Rx.merge([
      _decodeInvoiceController.stream.doOnData((event) => _log.info("decodeInvoiceController: $event")),
      _lightningLinks.linksNotifications
          .map((data) => InputData(data: data, source: InputSource.hyperlink))
          .doOnData((event) => _log.info("lightningLinks: $event")),
      _deviceClient.clipboardStream
          .distinct()
          .skip(1)
          .map((data) => InputData(data: data, source: InputSource.clipboard))
          .doOnData((event) => _log.info("clipboardStream: $event")),
    ]).asyncMap((input) async {
      _log.info("Incoming input: '$input'");
      // Emit an empty InputState with isLoading to display a loader on UI layer
      emit(const InputState.loading());
      try {
        final parsedInput = await parse(input: input.data);
        return await _handleParsedInput(parsedInput, input.source);
      } catch (e) {
        _log.severe("Failed to parse input", e);
        return const InputState.empty();
      }
    });
  }

  Future<InputState> handlePaymentRequest(InputType_Bolt11 inputData, InputSource source) async {
    _log.info("handlePaymentRequest: $inputData source: $source");
    final LNInvoice lnInvoice = inputData.invoice;

    final invoice = Invoice(
      bolt11: lnInvoice.bolt11,
      paymentHash: lnInvoice.paymentHash,
      description: lnInvoice.description ?? "",
      amountMsat: lnInvoice.amountMsat ?? BigInt.zero,
      expiry: lnInvoice.expiry,
    );
    return InputState.invoice(invoice, source);
  }

  Future<InputState> _handleParsedInput(InputType parsedInput, InputSource source) async {
    _log.info("handleParsedInput: $source => ${inputTypeToString(parsedInput)}");
    InputState result;
    if (parsedInput is InputType_Bolt11) {
      result = await handlePaymentRequest(parsedInput, source);
    } else if (parsedInput is InputType_LnUrlPay) {
      result = InputState.lnUrlPay(parsedInput.data, source);
    } else if (parsedInput is InputType_LnUrlWithdraw) {
      result = InputState.lnUrlWithdraw(parsedInput.data, source);
    } else if (parsedInput is InputType_LnUrlAuth) {
      result = InputState.lnUrlAuth(parsedInput.data, source);
    } else if (parsedInput is InputType_LnUrlError) {
      result = InputState.lnUrlError(parsedInput.data, source);
    } else if (parsedInput is InputType_NodeId) {
      result = InputState.nodeId(parsedInput.nodeId, source);
    } else if (parsedInput is InputType_BitcoinAddress) {
      result = InputState.bitcoinAddress(parsedInput.address, source);
    } else if (parsedInput is InputType_Url) {
      result = InputState.url(parsedInput.url, source);
    } else {
      result = const InputState.empty();
    }
    _log.fine("handleParsedInput: result: $result");
    return result;
  }

  Future<InputType> parseInput({required String input}) async {
    _log.info("parseInput: $input");
    return await parse(input: input);
  }
}
