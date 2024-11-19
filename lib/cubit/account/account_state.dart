import 'dart:convert';

import 'package:breez_liquid/breez_liquid.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('AccountState');

class AccountState {
  final bool isRestoring;
  final bool isOnboardingComplete;
  final bool didCompleteInitialSync;
  final GetInfoResponse? walletInfo;

  const AccountState({
    required this.isRestoring,
    required this.isOnboardingComplete,
    required this.didCompleteInitialSync,
    required this.walletInfo,
  });

  AccountState.initial()
      : this(
          isRestoring: false,
          isOnboardingComplete: false,
          didCompleteInitialSync: false,
          walletInfo: null,
        );

  AccountState copyWith({
    bool? isRestoring,
    bool? isOnboardingComplete,
    bool? didCompleteInitialSync,
    GetInfoResponse? walletInfo,
  }) {
    return AccountState(
      isRestoring: isRestoring ?? this.isRestoring,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      didCompleteInitialSync: didCompleteInitialSync ?? this.didCompleteInitialSync,
      walletInfo: walletInfo ?? this.walletInfo,
    );
  }

  bool get hasBalance => walletInfo != null && walletInfo!.balanceSat > BigInt.zero;

  Map<String, dynamic>? toJson() {
    return <String, dynamic>{
      'isRestoring': isRestoring,
      'isOnboardingComplete': isOnboardingComplete,
      'walletInfo': walletInfo?.toJson(),
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      isRestoring: json['isRestoring'] ?? false,
      isOnboardingComplete: json['isOnboardingComplete'] ?? false,
      didCompleteInitialSync: false,
      walletInfo: GetInfoResponseFromJson.fromJson(json['walletInfo']),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

extension GetInfoResponseToJson on GetInfoResponse {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'balanceSat': balanceSat.toString(),
      'pendingSendSat': pendingSendSat.toString(),
      'pendingReceiveSat': pendingReceiveSat.toString(),
      'fingerprint': fingerprint,
      'pubkey': pubkey,
    };
  }
}

extension GetInfoResponseFromJson on GetInfoResponse {
  static GetInfoResponse? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.info('walletInfo is missing from AccountState JSON.');
      return null;
    }

    if (json['balanceSat'] == null ||
        json['pendingSendSat'] == null ||
        json['pendingReceiveSat'] == null ||
        json['fingerprint'] == null ||
        json['pubkey'] == null) {
      _logger.warning('GetInfoResponse has missing fields on AccountState JSON.');
      return null;
    }

    return GetInfoResponse(
      balanceSat: BigInt.parse(json['balanceSat'] as String),
      pendingSendSat: BigInt.parse(json['pendingSendSat'] as String),
      pendingReceiveSat: BigInt.parse(json['pendingReceiveSat'] as String),
      fingerprint: json['fingerprint'] as String,
      pubkey: json['pubkey'] as String,
    );
  }
}
