import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:lightning_links/lightning_links.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

export 'input_state.dart';

final Logger _logger = Logger('InputCubit');

class InputCubit extends Cubit<InputState> {
  final BreezSDKLiquid _breezSdkLiquid;
  final LightningLinksService _lightningLinks;

  final StreamController<InputData> _decodeInvoiceController = StreamController<InputData>();

  InputCubit(
    this._breezSdkLiquid,
    this._lightningLinks,
  ) : super(const InputState.empty()) {
    _initializeInputCubit();
  }

  void _initializeInputCubit() async {
    _logger.info('initializeInputCubit');
    _watchIncomingInvoices().listen((InputState? inputState) => emit(inputState!));
  }

  void addIncomingInput(String input, InputSource source) {
    _logger.info('addIncomingInput: $input source: $source');
    _decodeInvoiceController.add(InputData(data: input, source: source));
  }

  Future<void> trackPaymentEvents(String? paymentDestination) async {
    _logger.info('Tracking incoming payment events for: $paymentDestination');
    final bool paymentDestinationIsEmpty = paymentDestination == null || paymentDestination.isEmpty;
    await _breezSdkLiquid.paymentEventStream.firstWhere((PaymentEvent paymentEvent) {
      final Payment payment = paymentEvent.payment;
      final String receivedPaymentDestination = payment.destination ?? '';
      final bool doesDestinationMatch =
          paymentDestinationIsEmpty || receivedPaymentDestination == paymentDestination;
      final bool isPaymentReceived = payment.paymentType == PaymentType.receive &&
          (payment.status == PaymentState.pending || payment.status == PaymentState.complete);

      if (doesDestinationMatch && isPaymentReceived) {
        _logger.info('Payment Received! Destination: ${payment.destination}, Status: ${payment.status}');
        return true;
      }
      return false;
    });
  }

  Stream<InputState?> _watchIncomingInvoices() {
    _logger.info('watchIncomingInvoices');
    return Rx.merge(<Stream<InputData>>[
      _decodeInvoiceController.stream
          .doOnData((InputData event) => _logger.info('decodeInvoiceController: $event')),
      _lightningLinks.linksNotifications
          .map((String data) => InputData(data: data, source: InputSource.hyperlink))
          .doOnData((InputData event) => _logger.info('lightningLinks: $event')),
    ]).asyncMap((InputData input) async {
      _logger.info("Incoming input: '$input'");
      // Emit an empty InputState with isLoading to display a loader on UI layer
      emit(const InputState.loading());
      try {
        final InputType parsedInput = await _breezSdkLiquid.instance!.parse(input: input.data);
        return await _handleParsedInput(parsedInput, input.source);
      } catch (e) {
        _logger.severe('Failed to parse input', e);
        return const InputState.empty();
      }
    });
  }

  Future<InputState> handlePaymentRequest(InputType_Bolt11 inputData, InputSource source) async {
    _logger.info('handlePaymentRequest: $inputData source: $source');
    return InputState.invoice(inputData.invoice, source);
  }

  Future<InputState> _handleParsedInput(InputType parsedInput, InputSource source) async {
    _logger.info('handleParsedInput: $source => ${parsedInput.toFormattedString()}');
    InputState result;
    if (parsedInput is InputType_Bolt11) {
      result = await handlePaymentRequest(parsedInput, source);
    } else if (parsedInput is InputType_Bolt12Offer) {
      result = InputState.bolt12Offer(parsedInput.offer, parsedInput.bip353Address, source);
    } else if (parsedInput is InputType_LnUrlPay) {
      result = InputState.lnUrlPay(parsedInput.data, parsedInput.bip353Address, source);
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
    _logger.fine('handleParsedInput: result: $result');
    return result;
  }

  Future<InputType> parseInput({required String input}) async {
    _logger.info('parseInput: $input');
    return await _breezSdkLiquid.instance!.parse(input: input);
  }
}
