import 'dart:convert';

class AccountState {
  final String? id;
  final String? fingerprint;
  final bool initial;
  final int balance;
  final int pendingSend;
  final int pendingReceive;
  final int walletBalance;

  const AccountState({
    required this.id,
    required this.fingerprint,
    required this.initial,
    required this.balance,
    required this.pendingSend,
    required this.pendingReceive,
    required this.walletBalance,
  });

  AccountState.initial()
      : this(
          id: null,
          fingerprint: null,
          initial: true,
          balance: 0,
          walletBalance: 0,
          pendingReceive: 0,
          pendingSend: 0,
        );

  AccountState copyWith({
    String? id,
    String? fingerprint,
    bool? initial,
    int? balance,
    int? pendingSend,
    int? pendingReceive,
    int? walletBalance,
  }) {
    return AccountState(
      id: id ?? this.id,
      fingerprint: fingerprint ?? this.fingerprint,
      initial: initial ?? this.initial,
      balance: balance ?? this.balance,
      pendingSend: pendingSend ?? this.pendingSend,
      pendingReceive: pendingReceive ?? this.pendingReceive,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }

  bool get hasBalance => balance > 0;

  Map<String, dynamic>? toJson() {
    return {
      "id": id,
      "fingerprint": fingerprint,
      "initial": initial,
      "balance": balance,
      "pendingSend": pendingSend,
      "pendingReceive": pendingReceive,
      "walletBalance": walletBalance,
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      id: json["id"],
      fingerprint: json["fingerprint"],
      initial: json["initial"],
      balance: json["balance"],
      pendingSend: json["pendingSend"],
      pendingReceive: json["pendingReceive"],
      walletBalance: json["walletBalance"],
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
