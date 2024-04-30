import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/bloc/account/payment_filters.dart';
import 'package:l_breez/models/payment_minutiae.dart';

import 'account_bloc.dart';
import 'account_state.dart';

// assembleAccountState assembles the account state using the local synchronized data.
AccountState? assembleAccountState(
  List<Payment>? payments,
  PaymentFilters paymentFilters,
  GetInfoResponse? nodeState,
  AccountState state,
) {
  if (nodeState == null) {
    return null;
  }

  final texts = getSystemAppLocalizations();
  // return the new account state
  return state.copyWith(
    id: nodeState.pubkey,
    initial: false,
    balance: nodeState.balanceSat.toInt(),
    pendingReceive: nodeState.pendingReceiveSat.toInt(),
    pendingSend: nodeState.pendingSendSat.toInt(),
    maxPaymentAmount: maxPaymentAmount,
    onChainFeeRate: 0,
    payments: payments?.map((e) => PaymentMinutiae.fromPayment(e, texts)).toList(),
    paymentFilters: paymentFilters,
    connectionStatus: ConnectionStatus.CONNECTED,
    verificationStatus: state.verificationStatus,
  );
}
