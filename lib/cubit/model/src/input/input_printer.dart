import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension InputTypeExtension on InputType {
  String toFormattedString() {
    return switch (this) {
      InputType_BitcoinAddress() => (this as InputType_BitcoinAddress).address.toFormattedString(),
      InputType_Bolt12Offer() => (this as InputType_Bolt12Offer).offer.toFormattedString() +
          ((this as InputType_Bolt12Offer).bip353Address == null
              ? ''
              : ', Bip 353 Address: ${(this as InputType_Bolt12Offer).bip353Address!}'),
      InputType_Bolt11() => (this as InputType_Bolt11).invoice.toFormattedString(),
      InputType_NodeId() => 'NodeId(nodeId: ${(this as InputType_NodeId).nodeId})',
      InputType_Url() => 'Url(url: ${(this as InputType_Url).url})',
      InputType_LnUrlPay() => (this as InputType_LnUrlPay).data.toFormattedString() +
          ((this as InputType_LnUrlPay).bip353Address == null
              ? ''
              : ', Bip 353 Address: ${(this as InputType_LnUrlPay).bip353Address!}'),
      InputType_LnUrlWithdraw() => (this as InputType_LnUrlWithdraw).data.toFormattedString(),
      InputType_LnUrlAuth() => (this as InputType_LnUrlAuth).data.toFormattedString(),
      InputType_LnUrlError() => (this as InputType_LnUrlError).data.toFormattedString(),
      _ => 'Unknown InputType',
    };
  }
}

extension BitcoinAddressDataExtension on BitcoinAddressData {
  String toFormattedString() =>
      'BitcoinAddressData(address: $address, network: $network, amountSat: $amountSat, '
      'label: $label, message: $message)';
}

extension LNInvoiceExtension on LNInvoice {
  String toFormattedString() =>
      'LNInvoice(invoice: $bolt11, paymentHash: $paymentHash, description: $description, '
      'amountMsat: $amountMsat, expiry: $expiry, payeePubkey: $payeePubkey, '
      'descriptionHash: $descriptionHash, timestamp: $timestamp, routingHints: $routingHints, '
      'paymentSecret: $paymentSecret)';
}

extension LNOfferExtension on LNOffer {
  String toFormattedString() =>
      'LNOffer(offer: $offer, description: $description, absoluteExpiry: $absoluteExpiry, '
      'chains: $chains, issuer: $issuer, minAmount: $minAmount, '
      'paths: ${paths.toFormattedString()}, signingPubkey: $signingPubkey)';
}

extension LnOfferBlindedPathExtension on List<LnOfferBlindedPath> {
  String toFormattedString() => map((LnOfferBlindedPath path) => path.blindedHops.toString()).join(', ');
}

extension LnUrlPayRequestDataExtension on LnUrlPayRequestData {
  String toFormattedString() => 'LnUrlPayRequestData(callback: $callback, minSendable: $minSendable, '
      'maxSendable: $maxSendable, metadataStr: $metadataStr, '
      'commentAllowed: $commentAllowed, domain: $domain, lnAddress: $lnAddress)';
}

extension LnUrlWithdrawRequestDataExtension on LnUrlWithdrawRequestData {
  String toFormattedString() =>
      'LnUrlWithdrawRequestData(callback: $callback, minWithdrawable: $minWithdrawable, '
      'maxWithdrawable: $maxWithdrawable, defaultDescription: $defaultDescription, k1: $k1)';
}

extension LnUrlAuthRequestDataExtension on LnUrlAuthRequestData {
  String toFormattedString() => 'LnUrlAuthRequestData(k1: $k1, action: $action, domain: $domain, url: $url)';
}

extension LnUrlErrorDataExtension on LnUrlErrorData {
  String toFormattedString() => 'LnUrlErrorData(reason: $reason)';
}
