import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension PreparePayOnchainResponseAffordable on PreparePayOnchainResponse {
  bool isAffordable({required int balance}) {
    return balance >= (receiverAmountSat + totalFeesSat).toInt();
  }
}
