import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension ConfigCopyWith on Config {
  Config copyWith({
    String? liquidElectrumUrl,
    String? bitcoinElectrumUrl,
    String? workingDir,
    LiquidNetwork? network,
    BigInt? paymentTimeoutSec,
    int? zeroConfMinFeeRateMsat,
  }) {
    return Config(
      liquidElectrumUrl: liquidElectrumUrl ?? this.liquidElectrumUrl,
      bitcoinElectrumUrl: bitcoinElectrumUrl ?? this.bitcoinElectrumUrl,
      workingDir: workingDir ?? this.workingDir,
      network: network ?? this.network,
      paymentTimeoutSec: paymentTimeoutSec ?? this.paymentTimeoutSec,
      zeroConfMinFeeRateMsat: zeroConfMinFeeRateMsat ?? this.zeroConfMinFeeRateMsat,
    );
  }
}
