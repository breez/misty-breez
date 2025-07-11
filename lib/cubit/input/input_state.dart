import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';

typedef TypeCheck = bool Function(InputType);

final List<TypeCheck> unsupportedInputTypeChecks = <TypeCheck>[
  (InputType input) => input is InputType_NodeId,
  (InputType input) => input is InputType_Url,
];

const Set<Type> unsupportedInputStates = <Type>{NodeIdInputState, UrlInputState};

class InputState {
  const InputState._();

  const factory InputState.empty() = EmptyInputState;

  const factory InputState.loading() = LoadingInputState;

  const factory InputState.invoice(LNInvoice invoice, InputSource source) = LnInvoiceInputState;

  const factory InputState.bolt12Offer(LNOffer lnOffer, String? bip353Address, InputSource source) =
      LnOfferInputState;

  const factory InputState.lnUrlPay(LnUrlPayRequestData data, String? bip353Address, InputSource source) =
      LnUrlPayInputState;

  const factory InputState.lnUrlWithdraw(LnUrlWithdrawRequestData data, InputSource source) =
      LnUrlWithdrawInputState;

  const factory InputState.lnUrlAuth(LnUrlAuthRequestData data, InputSource source) = LnUrlAuthInputState;

  const factory InputState.lnUrlError(LnUrlErrorData data, InputSource source) = LnUrlErrorInputState;

  const factory InputState.nodeId(String nodeId, InputSource source) = NodeIdInputState;

  const factory InputState.bitcoinAddress(BitcoinAddressData data, InputSource source) =
      BitcoinAddressInputState;

  const factory InputState.url(String url, InputSource source) = UrlInputState;
}

class EmptyInputState extends InputState {
  const EmptyInputState() : super._();

  @override
  String toString() {
    return 'EmptyInputState{}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmptyInputState && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

class LoadingInputState extends InputState {
  const LoadingInputState() : super._();

  @override
  String toString() {
    return 'LoadingInputState{}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LoadingInputState && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

class LnInvoiceInputState extends InputState {
  const LnInvoiceInputState(this.lnInvoice, this.source) : super._();

  final LNInvoice lnInvoice;
  final InputSource source;

  @override
  String toString() {
    return 'LnInvoiceInputState{lnInvoice: $lnInvoice, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LnInvoiceInputState &&
          runtimeType == other.runtimeType &&
          lnInvoice == other.lnInvoice &&
          source == other.source;

  @override
  int get hashCode => Object.hash(lnInvoice, source);
}

class LnOfferInputState extends InputState {
  const LnOfferInputState(this.lnOffer, this.bip353Address, this.source) : super._();

  final LNOffer lnOffer;
  final String? bip353Address;
  final InputSource source;

  @override
  String toString() {
    return 'LnOfferInputState{lnOffer: ${lnOffer.toFormattedString()}, bip353Address: $bip353Address, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LnOfferInputState &&
          runtimeType == other.runtimeType &&
          lnOffer == other.lnOffer &&
          bip353Address == other.bip353Address &&
          source == other.source;

  @override
  int get hashCode => Object.hash(lnOffer, bip353Address, source);
}

class LnUrlPayInputState extends InputState {
  const LnUrlPayInputState(this.data, this.bip353Address, this.source) : super._();

  final LnUrlPayRequestData data;
  final String? bip353Address;
  final InputSource source;

  @override
  String toString() {
    return 'LnUrlPayInputState{data: ${data.toFormattedString()}, bip353Address: $bip353Address, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LnUrlPayInputState &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          bip353Address == other.bip353Address &&
          source == other.source;

  @override
  int get hashCode => Object.hash(data, bip353Address, source);
}

class LnUrlWithdrawInputState extends InputState {
  const LnUrlWithdrawInputState(this.data, this.source) : super._();

  final LnUrlWithdrawRequestData data;
  final InputSource source;

  @override
  String toString() {
    return 'LnUrlWithdrawInputState{data: ${data.toFormattedString()}, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LnUrlWithdrawInputState &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          source == other.source;

  @override
  int get hashCode => Object.hash(data, source);
}

class LnUrlAuthInputState extends InputState {
  const LnUrlAuthInputState(this.data, this.source) : super._();

  final LnUrlAuthRequestData data;
  final InputSource source;

  @override
  String toString() {
    return 'LnUrlAuthInputState{data: ${data.toFormattedString()}, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LnUrlAuthInputState &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          source == other.source;

  @override
  int get hashCode => Object.hash(data, source);
}

class LnUrlErrorInputState extends InputState {
  const LnUrlErrorInputState(this.data, this.source) : super._();

  final LnUrlErrorData data;
  final InputSource source;

  @override
  String toString() {
    return 'LnUrlErrorInputState{data: ${data.toFormattedString()}, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LnUrlErrorInputState &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          source == other.source;

  @override
  int get hashCode => Object.hash(data, source);
}

class NodeIdInputState extends InputState {
  const NodeIdInputState(this.nodeId, this.source) : super._();

  final String nodeId;
  final InputSource source;

  @override
  String toString() {
    return 'NodeIdInputState{nodeId: $nodeId, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeIdInputState &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          source == other.source;

  @override
  int get hashCode => Object.hash(nodeId, source);
}

class BitcoinAddressInputState extends InputState {
  const BitcoinAddressInputState(this.data, this.source) : super._();

  final BitcoinAddressData data;
  final InputSource source;

  @override
  String toString() {
    return 'BitcoinAddressInputState{data: ${data.toFormattedString()}, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BitcoinAddressInputState &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          source == other.source;

  @override
  int get hashCode => Object.hash(data, source);
}

class UrlInputState extends InputState {
  const UrlInputState(this.url, this.source) : super._();

  final String url;
  final InputSource source;

  @override
  String toString() {
    return 'UrlInputState{url: $url, source: $source}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrlInputState &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          source == other.source;

  @override
  int get hashCode => Object.hash(url, source);
}
