// TODO(erdemyerebasmaz): Liquid - This file is unused - Re-add for swap tx's after input parser is implemented
class BlockChainExplorerUtils {
  String formatTransactionUrl({
    required String txid,
    String mempoolInstance = 'https://liquid.fra.mempool.space/',
    String unblindingData = '',
  }) {
    final String blinded = unblindingData.isEmpty ? '' : '#blinded=$unblindingData';
    return '$mempoolInstance/tx/$txid$blinded';
  }

  String formatRecommendedFeesUrl({String mempoolInstance = 'https://liquid.fra.mempool.space/'}) {
    return '$mempoolInstance/api/v1/fees/recommended';
  }
}
