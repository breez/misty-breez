import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension AssetBalanceToJson on AssetBalance {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'assetId': assetId,
      'balanceSat': balanceSat.toString(),
      'name': name,
      'ticker': ticker,
      'balance': balance?.toString(),
    };
  }
}

extension AssetBalanceFromJson on AssetBalance {
  static AssetBalance fromJson(Map<String, dynamic> json) {
    return AssetBalance(
      assetId: json['assetId'] as String,
      balanceSat: BigInt.parse(json['balanceSat'] as String),
      name: json['name'] as String?,
      ticker: json['ticker'] as String?,
      balance: json['balance'] != null ? double.parse(json['balance'] as String) : null,
    );
  }
}

extension AssetInfoToJson on AssetInfo {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'ticker': ticker,
      'amount': amount.toString(),
    };
  }
}

extension AssetInfoFromJson on AssetInfo {
  static AssetInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return AssetInfo(
      name: json['name'] as String,
      ticker: json['ticker'] as String,
      amount: double.parse(json['amount'] as String),
    );
  }
}
