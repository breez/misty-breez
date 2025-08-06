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
    BigInt? onchainFeeRateLeewaySat,
    List<AssetMetadata>? assetMetadata,
    String? sideswapApiKey,
    bool? useMagicRoutingHints,
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
      onchainFeeRateLeewaySat: onchainFeeRateLeewaySat ?? this.onchainFeeRateLeewaySat,
      assetMetadata: assetMetadata ?? this.assetMetadata,
      sideswapApiKey: sideswapApiKey ?? this.sideswapApiKey,
      useMagicRoutingHints: useMagicRoutingHints ?? this.useMagicRoutingHints,
    );
  }
}
