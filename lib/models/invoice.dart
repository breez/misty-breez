import 'package:l_breez/utils/extensions/breez_pos_message_extractor.dart';

class Invoice {
  final String bolt11;
  final String paymentHash;
  final String description;
  final BigInt amountMsat;
  final BigInt expiry;
  final int lspFee;

  const Invoice({
    required this.bolt11,
    required this.paymentHash,
    this.description = "",
    required this.amountMsat,
    required this.expiry,
    this.lspFee = 0,
  });

  String get payeeName => "";

  String get payerName => "";

  String get payerImageURL => "";

  String get payeeImageURL => "";

  String extractDescription() {
    return extractPosMessage(description) ?? description;
  }

  @override
  String toString() {
    return 'Invoice{bolt11: $bolt11, paymentHash: $paymentHash, description: $description, '
        'amountMsat: $amountMsat, expiry: $expiry, lspFee: $lspFee}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice &&
          runtimeType == other.runtimeType &&
          bolt11 == other.bolt11 &&
          paymentHash == other.paymentHash &&
          description == other.description &&
          amountMsat == other.amountMsat &&
          expiry == other.expiry &&
          lspFee == other.lspFee;

  @override
  int get hashCode =>
      bolt11.hashCode ^
      paymentHash.hashCode ^
      description.hashCode ^
      amountMsat.hashCode ^
      expiry.hashCode ^
      lspFee.hashCode;
}
