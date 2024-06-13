import 'dart:async';

import 'package:breez_sdk/sdk.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:l_breez/bloc/input/input_data.dart';
import 'package:l_breez/bloc/input/input_printer.dart';
import 'package:l_breez/bloc/input/input_source.dart';
import 'package:l_breez/bloc/input/input_state.dart';
import 'package:l_breez/models/invoice.dart';
import 'package:l_breez/services/device.dart';
import 'package:l_breez/services/injector.dart';
import 'package:l_breez/services/lightning_links.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

class InputBloc extends Cubit<InputState> {
  final _log = Logger("InputBloc");
  final LightningLinksService _lightningLinks;
  final Device _device;

  final _decodeInvoiceController = StreamController<InputData>();

  InputBloc(
    this._lightningLinks,
    this._device,
  ) : super(const InputState.empty()) {
    _initializeInputBloc();
  }

  void _initializeInputBloc() async {
    _log.info("initializeInputBloc");
    _watchIncomingInvoices().listen((inputState) => emit(inputState!));
  }

  void addIncomingInput(String bolt11, InputSource source) {
    _log.info("addIncomingInput: $bolt11 source: $source");
    _decodeInvoiceController.add(InputData(data: bolt11, source: source));
  }

  Future trackPayment(String? invoiceId) async {
    _log.info("Tracking incoming payment: $invoiceId");
    await ServiceInjector().liquidSDK.paymentsStream.firstWhere(
      (paymentList) {
        if (paymentList.any((e) => e.swapId == invoiceId)) {
          if (invoiceId != null && invoiceId.isNotEmpty) {
            _log.info("Payment Received! Id: $invoiceId");
            return true;
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
      _device.clipboardStream
          .distinct()
          .skip(1)
          .map((data) => InputData(data: data, source: InputSource.clipboard))
          .doOnData((event) => _log.info("clipboardStream: $event")),
    ]).asyncMap((input) async {
      _log.info("Incoming input: '$input'");
      // Emit an empty InputState with isLoading to display a loader on UI layer
      emit(const InputState.loading());
      try {
        /*
        final parsedInput = await parseInput(input: input.data);
        return await _handleParsedInput(parsedInput, input.source);
         */
        final parsedInput = parseInvoice(input: input.data);
        final req = liquid_sdk.PrepareSendRequest(invoice: parsedInput.bolt11);
        final resp = await ServiceInjector().liquidSDK.wallet!.prepareSendPayment(req: req);
        // TODO: Liquid/FRB - Address BigInt & Int changes
        return InputState.invoice(
          Invoice(
            bolt11: resp.invoice,
            paymentHash: parsedInput.paymentHash,
            description: parsedInput.description ?? "",
            amountMsat: parsedInput.amountMsat ?? BigInt.zero,
            expiry: parsedInput.expiry,
            lspFee: resp.feesSat.toInt(),
          ),
          input.source,
        );
      } catch (e) {
        // TODO: Liquid - Revert back to "Failed to parse input" once InputParser is fully integrated into Liquid SDK
        _log.severe("Failed to prepare Send Payment", e);
        return const InputState.empty();
      }
    });
  }

  Future<InputState> handlePaymentRequest(InputType_Bolt11 inputData, InputSource source) async {
    _log.info("handlePaymentRequest: $inputData source: $source");
    final LNInvoice lnInvoice = inputData.invoice;

    /*NodeState? nodeState = await _breezSDK.nodeInfo();
    if (nodeState == null || nodeState.id == lnInvoice.payeePubkey) {
      return const InputState.empty();
    }*/
    final invoice = Invoice(
      bolt11: lnInvoice.bolt11,
      paymentHash: lnInvoice.paymentHash,
      description: lnInvoice.description ?? "",
      amountMsat: lnInvoice.amountMsat ?? BigInt.zero,
      expiry: lnInvoice.expiry,
    );
    return InputState.invoice(invoice, source);
  }

  // TODO: Liquid - Implement input parser to parse bolt11 invoice - https://github.com/breez/breez-liquid-sdk/issues/232
  // ignore: unused_element
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

  liquid_sdk.LNInvoice parseInvoice({required String input}) {
    _log.info("parseInvoice: $input");
    return liquid_sdk.parseInvoice(input: input);
  }
}
