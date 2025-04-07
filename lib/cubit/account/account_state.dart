import 'dart:convert';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/models/models.dart';

final Logger _logger = Logger('AccountState');

class AccountState {
  final bool isRestoring;
  final bool didCompleteInitialSync;
  final WalletInfo? walletInfo;
  final BlockchainInfo? blockchainInfo;

  const AccountState({
    required this.isRestoring,
    required this.didCompleteInitialSync,
    required this.walletInfo,
    required this.blockchainInfo,
  });

  AccountState.initial()
      : this(
          isRestoring: false,
          didCompleteInitialSync: false,
          walletInfo: null,
          blockchainInfo: null,
        );

  AccountState copyWith({
    bool? isRestoring,
    bool? didCompleteInitialSync,
    WalletInfo? walletInfo,
    BlockchainInfo? blockchainInfo,
  }) {
    return AccountState(
      isRestoring: isRestoring ?? this.isRestoring,
      didCompleteInitialSync: didCompleteInitialSync ?? this.didCompleteInitialSync,
      walletInfo: walletInfo ?? this.walletInfo,
      blockchainInfo: blockchainInfo ?? this.blockchainInfo,
    );
  }

  bool get hasBalance => walletInfo != null && walletInfo!.balanceSat > BigInt.zero;

  Map<String, dynamic>? toJson() {
    return <String, dynamic>{
      'isRestoring': isRestoring,
      'walletInfo': walletInfo?.toJson(),
      'blockchainInfo': blockchainInfo?.toJson(),
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      isRestoring: json['isRestoring'] ?? false,
      didCompleteInitialSync: false,
      walletInfo: WalletInfoFromJson.fromJson(json['walletInfo']),
      blockchainInfo: BlockchainInfoFromJson.fromJson(json['blockchainInfo']),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

extension WalletInfoToJson on WalletInfo {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'balanceSat': balanceSat.toString(),
      'pendingSendSat': pendingSendSat.toString(),
      'pendingReceiveSat': pendingReceiveSat.toString(),
      'fingerprint': fingerprint,
      'pubkey': pubkey,
      'assetBalances': assetBalances.map((AssetBalance assetBalance) => assetBalance.toJson()).toList(),
    };
  }
}

extension WalletInfoFromJson on WalletInfo {
  static WalletInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.info('walletInfo is missing from AccountState JSON.');
      return null;
    }

    try {
      final dynamic balanceSatValue = json['balanceSat'];
      final dynamic pendingSendSatValue = json['pendingSendSat'];
      final dynamic pendingReceiveSatValue = json['pendingReceiveSat'];

      // Handle both integer and string formats
      final BigInt balanceSat = balanceSatValue is String
          ? BigInt.parse(balanceSatValue)
          : BigInt.from(balanceSatValue as int? ?? 0);

      final BigInt pendingSendSat = pendingSendSatValue is String
          ? BigInt.parse(pendingSendSatValue)
          : BigInt.from(pendingSendSatValue as int? ?? 0);

      final BigInt pendingReceiveSat = pendingReceiveSatValue is String
          ? BigInt.parse(pendingReceiveSatValue)
          : BigInt.from(pendingReceiveSatValue as int? ?? 0);

      return WalletInfo(
        balanceSat: balanceSat,
        pendingSendSat: pendingSendSat,
        pendingReceiveSat: pendingReceiveSat,
        fingerprint: json['fingerprint'] as String? ?? '',
        pubkey: json['pubkey'] as String? ?? '',
        assetBalances: json['assetBalances'] != null
            ? (json['assetBalances'] as List<dynamic>)
                .map((dynamic json) => AssetBalanceFromJson.fromJson(json))
                .toList()
            : <AssetBalance>[],
      );
    } catch (e, stack) {
      _logger.severe('Error parsing WalletInfo from JSON: $e\n$stack');
      return null;
    }
  }
}

extension BlockchainInfoToJson on BlockchainInfo {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'liquidTip': liquidTip.toString(),
      'bitcoinTip': bitcoinTip.toString(),
    };
  }
}

extension BlockchainInfoFromJson on BlockchainInfo {
  static BlockchainInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.info('blockchainInfo is missing from AccountState JSON.');
      return null;
    }

    try {
      final dynamic liquidTipValue = json['liquidTip'];
      final dynamic bitcoinTipValue = json['bitcoinTip'];

      // Handle both integer and string formats
      final int liquidTip =
          liquidTipValue is String ? int.parse(liquidTipValue) : (liquidTipValue as int? ?? 0);

      final int bitcoinTip =
          bitcoinTipValue is String ? int.parse(bitcoinTipValue) : (bitcoinTipValue as int? ?? 0);

      return BlockchainInfo(
        liquidTip: liquidTip,
        bitcoinTip: bitcoinTip,
      );
    } catch (e, stack) {
      _logger.severe('Error parsing BlockchainInfo from JSON: $e\n$stack');
      return null;
    }
  }
}
