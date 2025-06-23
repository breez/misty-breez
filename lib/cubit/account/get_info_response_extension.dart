import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';

final Logger _logger = Logger('AccountCubit');

extension GetInfoResponseLogging on GetInfoResponse {
  void logChanges(AccountState oldState) {
    final WalletInfo? oldWallet = oldState.walletInfo;
    final BlockchainInfo? oldChain = oldState.blockchainInfo;
    final WalletInfo newWallet = walletInfo;
    final BlockchainInfo newChain = blockchainInfo;

    if (oldWallet != null) {
      _logWalletChanges(oldWallet, newWallet);
    }
    if (oldChain != null) {
      _logBlockchainChanges(oldChain, newChain);
    }
  }

  void _logWalletChanges(WalletInfo old, WalletInfo newInfo) {
    _logChange('balanceSat', old.balanceSat, newInfo.balanceSat);
    _logChange('pendingSendSat', old.pendingSendSat, newInfo.pendingSendSat);
    _logChange('pendingReceiveSat', old.pendingReceiveSat, newInfo.pendingReceiveSat);
    _logChange('fingerprint', old.fingerprint, newInfo.fingerprint);
    _logChange('pubkey', old.pubkey, newInfo.pubkey);

    if (old.assetBalances.length != newInfo.assetBalances.length ||
        !old.assetBalances.deepEquals(newInfo.assetBalances)) {
      _logger.info(
        'AccountState changed. assetBalances: length=${old.assetBalances.length} → ${newInfo.assetBalances.length} or content modified',
      );
    }
  }

  void _logBlockchainChanges(BlockchainInfo old, BlockchainInfo newInfo) {
    _logChange('liquidTip', old.liquidTip, newInfo.liquidTip);
    _logChange('bitcoinTip', old.bitcoinTip, newInfo.bitcoinTip);
  }

  void _logChange(String field, Object? oldVal, Object? newVal) {
    if (oldVal != newVal) {
      _logger.info('AccountState changed. $field: $oldVal → $newVal');
    }
  }
}
