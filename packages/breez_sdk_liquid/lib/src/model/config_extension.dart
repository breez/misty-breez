import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension ConfigCopyWith on Config {
  Config copyWith({
    String? liquidElectrumUrl,
    String? bitcoinElectrumUrl,
    String? mempoolspaceUrl,
    String? workingDir,
    LiquidNetwork? network,
    BigInt? paymentTimeoutSec,
    int? zeroConfMinFeeRateMsat,
  }) {
    return Config(
      liquidElectrumUrl: liquidElectrumUrl ?? this.liquidElectrumUrl,
      bitcoinElectrumUrl: bitcoinElectrumUrl ?? this.bitcoinElectrumUrl,
      mempoolspaceUrl: mempoolspaceUrl ?? this.mempoolspaceUrl,
      workingDir: workingDir ?? this.workingDir,
      network: network ?? this.network,
      paymentTimeoutSec: paymentTimeoutSec ?? this.paymentTimeoutSec,
      zeroConfMinFeeRateMsat: zeroConfMinFeeRateMsat ?? this.zeroConfMinFeeRateMsat,
    );
  }
}
