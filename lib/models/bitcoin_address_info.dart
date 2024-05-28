import 'package:l_breez/models/currency.dart';

// TODO: Liquid - This file is unused - Re-add for swap tx's after input parser is implemented
class BitcoinAddressInfo {
  final String? address;
  final int? satAmount;

  const BitcoinAddressInfo(
    this.address,
    this.satAmount,
  );

  factory BitcoinAddressInfo.fromScannedString(String? scannedString) {
    String? address;
    int? satAmount;
    if (scannedString != null) {
      final uri = Uri.tryParse(scannedString);
      if (uri != null) {
        address = uri.path;
        final amount = uri.queryParameters["amount"];
        if (amount != null) {
          final btcAmount = double.tryParse(amount);
          if (btcAmount != null) {
            satAmount = BitcoinCurrency.BTC.toSats(btcAmount);
          }
        }
      }
    }
    return BitcoinAddressInfo(address, satAmount);
  }
}
