import 'dart:convert';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/utils/utils.dart';

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isRestoring': isRestoring,
      'walletInfo': walletInfo?.toJson(),
      'blockchainInfo': blockchainInfo?.toJson(),
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      isRestoring: json['isRestoring'] as bool? ?? false,
      didCompleteInitialSync: false,
      walletInfo: WalletInfoFromJson.fromJson(json['walletInfo'] as Map<String, dynamic>?),
      blockchainInfo: BlockchainInfoFromJson.fromJson(json['blockchainInfo'] as Map<String, dynamic>?),
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

    final List<String> requiredFields = <String>[
      'balanceSat',
      'pendingSendSat',
      'pendingReceiveSat',
      'fingerprint',
      'pubkey',
      'assetBalances',
    ];
    final List<String> missingFields = requiredFields.where((String field) => json[field] == null).toList();
    if (missingFields.isNotEmpty) {
      _logger.warning('WalletInfo missing required fields: ${missingFields.join(', ')}');
      return null;
    }

    try {
      return WalletInfo(
        balanceSat: JsonParsingUtils.parseToBigInt(json['balanceSat'], fieldName: 'balanceSat'),
        pendingSendSat: JsonParsingUtils.parseToBigInt(json['pendingSendSat'], fieldName: 'pendingSendSat'),
        pendingReceiveSat:
            JsonParsingUtils.parseToBigInt(json['pendingReceiveSat'], fieldName: 'pendingReceiveSat'),
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

    final List<String> requiredFields = <String>['liquidTip', 'bitcoinTip'];
    final List<String> missingFields = requiredFields.where((String field) => json[field] == null).toList();
    if (missingFields.isNotEmpty) {
      _logger.warning('BlockchainInfo missing required fields: ${missingFields.join(', ')}');
      return null;
    }

    try {
      return BlockchainInfo(
        liquidTip: JsonParsingUtils.parseToInt(json['liquidTip'], fieldName: 'liquidTip'),
        bitcoinTip: JsonParsingUtils.parseToInt(json['bitcoinTip'], fieldName: 'bitcoinTip'),
      );
    } catch (e, stack) {
      _logger.severe('Error parsing BlockchainInfo from JSON: $e\n$stack');
      return null;
    }
  }
}
