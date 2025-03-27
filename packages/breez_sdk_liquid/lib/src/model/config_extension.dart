import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension ConfigCopyWith on Config {
  Config copyWith({
    BlockchainExplorer? liquidExplorer,
    BlockchainExplorer? bitcoinExplorer,
    String? workingDir,
    LiquidNetwork? network,
    BigInt? paymentTimeoutSec,
    int? zeroConfMinFeeRateMsat,
    BigInt? zeroConfMaxAmountSat,
    String? breezApiKey,
    List<ExternalInputParser>? externalInputParsers,
    String? syncServiceUrl,
    List<AssetMetadata>? assetMetadata,
  }) {
    return Config(
      liquidExplorer: liquidExplorer ?? this.liquidExplorer,
      bitcoinExplorer: bitcoinExplorer ?? this.bitcoinExplorer,
      workingDir: workingDir ?? this.workingDir,
      network: network ?? this.network,
      paymentTimeoutSec: paymentTimeoutSec ?? this.paymentTimeoutSec,
      zeroConfMaxAmountSat: zeroConfMaxAmountSat ?? this.zeroConfMaxAmountSat,
      breezApiKey: breezApiKey ?? this.breezApiKey,
      externalInputParsers: externalInputParsers ?? this.externalInputParsers,
      syncServiceUrl: syncServiceUrl ?? this.syncServiceUrl,
      useDefaultExternalInputParsers: true,
      assetMetadata: assetMetadata ?? this.assetMetadata,
    );
  }
}
