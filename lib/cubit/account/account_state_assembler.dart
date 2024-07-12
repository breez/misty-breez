import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:l_breez/cubit/model/src/payment/payment_filters.dart';
import 'package:l_breez/models/payment_minutiae.dart';

// assembleAccountState assembles the account state using the local synchronized data.
AccountState? assembleAccountState(
  List<Payment>? payments,
  PaymentFilters paymentFilters,
  GetInfoResponse? walletInfo,
  AccountState state,
) {
  if (walletInfo == null) {
    return null;
  }

  final texts = getSystemAppLocalizations();
  // return the new account state
  return state.copyWith(
    id: walletInfo.pubkey,
    initial: false,
    balance: walletInfo.balanceSat.toInt(),
    pendingReceive: walletInfo.pendingReceiveSat.toInt(),
    pendingSend: walletInfo.pendingSendSat.toInt(),
    maxPaymentAmount: maxPaymentAmount,
    onChainFeeRate: 0,
    payments: payments?.map((e) => PaymentMinutiae.fromPayment(e, texts)).toList(),
    paymentFilters: paymentFilters,
    connectionStatus: ConnectionStatus.connected,
    verificationStatus: state.verificationStatus,
  );
}
