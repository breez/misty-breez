import 'dart:convert';

import 'package:l_breez/bloc/account/payment_filters.dart';
import 'package:l_breez/models/payment_minutiae.dart';

const initialInboundCapacity = 4000000;

enum ConnectionStatus { CONNECTING, CONNECTED, DISCONNECTED }

enum VerificationStatus { UNVERIFIED, VERIFIED }

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
  final int maxPaymentAmount;
  final int maxChanReserve;
  final List<String> connectedPeers;
  final int maxInboundLiquidity;
  final int onChainFeeRate;
  final List<PaymentMinutiae> payments;
  final PaymentFilters paymentFilters;
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
    required this.maxPaymentAmount,
    required this.maxChanReserve,
    required this.connectedPeers,
    required this.maxInboundLiquidity,
    required this.onChainFeeRate,
    required this.payments,
    required this.paymentFilters,
    required this.connectionStatus,
    this.verificationStatus = VerificationStatus.UNVERIFIED,
  });

  AccountState.initial()
      : this(
          id: null,
          initial: true,
          blockheight: 0,
          maxAllowedToPay: 0,
          maxAllowedToReceive: 0,
          maxPaymentAmount: 0,
          maxChanReserve: 0,
          connectedPeers: List.empty(),
          maxInboundLiquidity: 0,
          onChainFeeRate: 0,
          balance: 0,
          walletBalance: 0,
          pendingReceive: 0,
          pendingSend: 0,
          payments: [],
          paymentFilters: PaymentFilters.initial(),
          connectionStatus: null,
          verificationStatus: VerificationStatus.UNVERIFIED,
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
    int? maxPaymentAmount,
    int? maxChanReserve,
    List<String>? connectedPeers,
    int? maxInboundLiquidity,
    int? onChainFeeRate,
    List<PaymentMinutiae>? payments,
    PaymentFilters? paymentFilters,
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
      maxPaymentAmount: maxPaymentAmount ?? this.maxPaymentAmount,
      blockheight: blockheight ?? this.blockheight,
      maxChanReserve: maxChanReserve ?? this.maxChanReserve,
      connectedPeers: connectedPeers ?? this.connectedPeers,
      maxInboundLiquidity: maxInboundLiquidity ?? this.maxInboundLiquidity,
      onChainFeeRate: onChainFeeRate ?? this.onChainFeeRate,
      payments: payments ?? this.payments,
      paymentFilters: paymentFilters ?? this.paymentFilters,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  int get reserveAmount => balance - maxAllowedToPay;

  bool get isFeesApplicable => maxAllowedToReceive > maxInboundLiquidity;

  // TODO: Add payments toJson
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
      "maxPaymentAmount": maxPaymentAmount,
      "maxChanReserve": maxChanReserve,
      "maxInboundLiquidity": maxInboundLiquidity,
      "onChainFeeRate": onChainFeeRate,
      "paymentFilters": paymentFilters.toJson(),
      "connectionStatus": connectionStatus?.index,
      "verificationStatus": verificationStatus?.index,
    };
  }

  // TODO: Generate payments fromJson
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
      maxPaymentAmount: json["maxPaymentAmount"],
      maxChanReserve: json["maxChanReserve"],
      connectedPeers: <String>[],
      maxInboundLiquidity: json["maxInboundLiquidity"] ?? 0,
      onChainFeeRate: (json["onChainFeeRate"]),
      payments: [],
      paymentFilters: PaymentFilters.fromJson(json["paymentFilters"]),
      connectionStatus: json["connectionStatus"] != null
          ? ConnectionStatus.values[json["connectionStatus"]]
          : ConnectionStatus.CONNECTING,
      verificationStatus: json["verificationStatus"] != null
          ? VerificationStatus.values[json["verificationStatus"]]
          : VerificationStatus.UNVERIFIED,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
