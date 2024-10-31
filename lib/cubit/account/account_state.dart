import 'dart:convert';

import 'package:breez_liquid/breez_liquid.dart';
import 'package:logging/logging.dart';

final _log = Logger("AccountState");

class AccountState {
  final bool isInitial;
  final GetInfoResponse? walletInfo;

  const AccountState({required this.isInitial, required this.walletInfo});

  AccountState.initial() : this(isInitial: true, walletInfo: null);

  AccountState copyWith({
    bool? isInitial,
    GetInfoResponse? walletInfo,
  }) {
    return AccountState(
      isInitial: isInitial ?? this.isInitial,
      walletInfo: walletInfo ?? this.walletInfo,
    );
  }

  bool get hasBalance => walletInfo != null && walletInfo!.balanceSat > BigInt.zero;

  Map<String, dynamic>? toJson() {
    return {
      "isInitial": isInitial,
      "walletInfo": walletInfo?.toJson(),
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      isInitial: json["isInitial"] ?? true,
      walletInfo: GetInfoResponseFromJson.fromJson(json['walletInfo']),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

extension GetInfoResponseToJson on GetInfoResponse {
  Map<String, dynamic> toJson() {
    return {
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
      _log.info("walletInfo is missing from AccountState JSON.");
      return null;
    }

    if (json['balanceSat'] == null ||
        json['pendingSendSat'] == null ||
        json['pendingReceiveSat'] == null ||
        json['fingerprint'] == null ||
        json['pubkey'] == null) {
      _log.warning("GetInfoResponse has missing fields on AccountState JSON.");
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
