import 'dart:convert';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/models/asset_extension.dart';

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

    if (json['balanceSat'] == null ||
        json['pendingSendSat'] == null ||
        json['pendingReceiveSat'] == null ||
        json['fingerprint'] == null ||
        json['pubkey'] == null) {
      _logger.warning('WalletInfo has missing fields on AccountState JSON.');
      return null;
    }

    return WalletInfo(
      balanceSat: BigInt.parse(json['balanceSat'] as String),
      pendingSendSat: BigInt.parse(json['pendingSendSat'] as String),
      pendingReceiveSat: BigInt.parse(json['pendingReceiveSat'] as String),
      fingerprint: json['fingerprint'] as String,
      pubkey: json['pubkey'] as String,
      assetBalances: json['assetBalances'] != null
          ? (json['assetBalances'] as List<dynamic>)
              .map((dynamic json) => AssetBalanceFromJson.fromJson(json))
              .toList()
          : <AssetBalance>[],
    );
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

    if (json['liquidTip'] == null || json['bitcoinTip'] == null) {
      _logger.warning('BlockchainInfo has missing fields on AccountState JSON.');
      return null;
    }

    return BlockchainInfo(
      liquidTip: int.parse(json['liquidTip'] as String),
      bitcoinTip: int.parse(json['bitcoinTip'] as String),
    );
  }
}
