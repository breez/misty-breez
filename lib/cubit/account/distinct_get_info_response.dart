import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/models/models.dart';

class DistinctGetInfoResponse {
  final GetInfoResponse inner;

  const DistinctGetInfoResponse(this.inner);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DistinctGetInfoResponse) {
      return false;
    }

    final WalletInfo a = inner.walletInfo;
    final WalletInfo b = other.inner.walletInfo;

    return a.balanceSat == b.balanceSat &&
        a.pendingSendSat == b.pendingSendSat &&
        a.pendingReceiveSat == b.pendingReceiveSat &&
        a.fingerprint == b.fingerprint &&
        a.pubkey == b.pubkey &&
        a.assetBalances.deepEquals(b.assetBalances) &&
        inner.blockchainInfo == other.inner.blockchainInfo;
  }

  @override
  int get hashCode {
    final WalletInfo a = inner.walletInfo;
    int listHash = 0;
    for (final AssetBalance item in a.assetBalances) {
      listHash ^= item.hashCode;
    }
    return a.balanceSat.hashCode ^
        a.pendingSendSat.hashCode ^
        a.pendingReceiveSat.hashCode ^
        a.fingerprint.hashCode ^
        a.pubkey.hashCode ^
        listHash ^
        inner.blockchainInfo.hashCode;
  }
}
