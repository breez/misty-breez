import 'package:l_breez/utils/constants/app_constants.dart';

/// Utility service for constructing blockchain explorer URLs
class BlockchainExplorerService {
  /// Private constructor to prevent instantiation
  BlockchainExplorerService._();

  /// Formats a URL for viewing a transaction on a blockchain explorer
  ///
  /// [txid] Transaction ID to view
  /// [mempoolInstance] The blockchain explorer base URL. Defaults to a Liquid mempool instance.
  /// [unblindingData] Optional unblinding data for Liquid transactions
  /// Returns a formatted URL string
  static String formatTransactionUrl({
    required String txid,
    String mempoolInstance = NetworkConstants.defaultLiquidMempoolInstance,
    String unblindingData = '',
  }) {
    final String blinded = unblindingData.isEmpty ? '' : '#blinded=$unblindingData';
    return '$mempoolInstance/tx/$txid$blinded';
  }
}
