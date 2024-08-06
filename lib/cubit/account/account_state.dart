import 'dart:convert';

class AccountState {
  final String? id;
  final bool initial;
  final int balance;
  final int pendingSend;
  final int pendingReceive;
  final int walletBalance;

  const AccountState({
    required this.id,
    required this.initial,
    required this.balance,
    required this.pendingSend,
    required this.pendingReceive,
    required this.walletBalance,
  });

  AccountState.initial()
      : this(
          id: null,
          initial: true,
          balance: 0,
          walletBalance: 0,
          pendingReceive: 0,
          pendingSend: 0,
        );

  AccountState copyWith({
    String? id,
    bool? initial,
    int? balance,
    int? pendingSend,
    int? pendingReceive,
    int? walletBalance,
  }) {
    return AccountState(
      id: id ?? this.id,
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
