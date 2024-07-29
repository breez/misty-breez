import 'dart:convert';

import 'package:l_breez/utils/constants.dart' as constants;

const initialInboundCapacity = 4000000;

enum ConnectionStatus { connecting, connected, disconnected }

enum VerificationStatus { unverified, verified }

// TODO: Liquid - Remove non-applicable fields for Liquid SDK
class AccountState {
  final String? id;
  final bool initial;
  final int blockheight;
  final int balance;
  final int pendingSend;
  final int pendingReceive;
  final int walletBalance;
  final int maxAllowedToPay;
  final int maxAllowedToReceive;
  final int maxPaymentAmountSat;
  final int maxChanReserve;
  final List<String> connectedPeers;
  final int maxInboundLiquidity;
  final int onChainFeeRate;
  final ConnectionStatus? connectionStatus;
  final VerificationStatus? verificationStatus;

  const AccountState({
    required this.id,
    required this.initial,
    required this.blockheight,
    required this.balance,
    required this.pendingSend,
    required this.pendingReceive,
    required this.walletBalance,
    required this.maxAllowedToPay,
    required this.maxAllowedToReceive,
    required this.maxPaymentAmountSat,
    required this.maxChanReserve,
    required this.connectedPeers,
    required this.maxInboundLiquidity,
    required this.onChainFeeRate,
    required this.connectionStatus,
    this.verificationStatus = VerificationStatus.unverified,
  });

  AccountState.initial()
      : this(
          id: null,
          initial: true,
          blockheight: 0,
          maxAllowedToPay: 0,
          maxAllowedToReceive: 0,
          maxPaymentAmountSat: constants.maxPaymentAmountSat,
          maxChanReserve: 0,
          connectedPeers: List.empty(),
          maxInboundLiquidity: 0,
          onChainFeeRate: 0,
          balance: 0,
          walletBalance: 0,
          pendingReceive: 0,
          pendingSend: 0,
          connectionStatus: null,
          verificationStatus: VerificationStatus.unverified,
        );

  AccountState copyWith({
    String? id,
    bool? initial,
    int? blockheight,
    int? balance,
    int? pendingSend,
    int? pendingReceive,
    int? walletBalance,
    int? maxAllowedToPay,
    int? maxAllowedToReceive,
    int? maxPaymentAmountSat,
    int? maxChanReserve,
    List<String>? connectedPeers,
    int? maxInboundLiquidity,
    int? onChainFeeRate,
    ConnectionStatus? connectionStatus,
    VerificationStatus? verificationStatus,
  }) {
    return AccountState(
      id: id ?? this.id,
      initial: initial ?? this.initial,
      balance: balance ?? this.balance,
      pendingSend: pendingSend ?? this.pendingSend,
      pendingReceive: pendingReceive ?? this.pendingReceive,
      walletBalance: walletBalance ?? this.walletBalance,
      maxAllowedToPay: maxAllowedToPay ?? this.maxAllowedToPay,
      maxAllowedToReceive: maxAllowedToReceive ?? this.maxAllowedToReceive,
      maxPaymentAmountSat: maxPaymentAmountSat ?? this.maxPaymentAmountSat,
      blockheight: blockheight ?? this.blockheight,
      maxChanReserve: maxChanReserve ?? this.maxChanReserve,
      connectedPeers: connectedPeers ?? this.connectedPeers,
      maxInboundLiquidity: maxInboundLiquidity ?? this.maxInboundLiquidity,
      onChainFeeRate: onChainFeeRate ?? this.onChainFeeRate,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  int get reserveAmount => balance - maxAllowedToPay;

  bool get isFeesApplicable => maxAllowedToReceive > maxInboundLiquidity;

  bool get hasBalance => balance > 0;

  Map<String, dynamic>? toJson() {
    return {
      "id": id,
      "initial": initial,
      "blockheight": blockheight,
      "balance": balance,
      "pendingSend": pendingSend,
      "pendingReceive": pendingReceive,
      "walletBalance": walletBalance,
      "maxAllowedToPay": maxAllowedToPay,
      "maxAllowedToReceive": maxAllowedToReceive,
      "maxPaymentAmount": maxPaymentAmountSat,
      "maxChanReserve": maxChanReserve,
      "maxInboundLiquidity": maxInboundLiquidity,
      "onChainFeeRate": onChainFeeRate,
      "connectionStatus": connectionStatus?.index,
      "verificationStatus": verificationStatus?.index,
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      id: json["id"],
      initial: json["initial"],
      blockheight: json["blockheight"],
      balance: json["balance"],
      pendingSend: json["pendingSend"],
      pendingReceive: json["pendingReceive"],
      walletBalance: json["walletBalance"],
      maxAllowedToPay: json["maxAllowedToPay"],
      maxAllowedToReceive: json["maxAllowedToReceive"],
      maxPaymentAmountSat: json["maxPaymentAmount"],
      maxChanReserve: json["maxChanReserve"],
      connectedPeers: <String>[],
      maxInboundLiquidity: json["maxInboundLiquidity"] ?? 0,
      onChainFeeRate: (json["onChainFeeRate"]),
      connectionStatus: json["connectionStatus"] != null
          ? ConnectionStatus.values[json["connectionStatus"]]
          : ConnectionStatus.connecting,
      verificationStatus: json["verificationStatus"] != null
          ? VerificationStatus.values[json["verificationStatus"]]
          : VerificationStatus.unverified,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
