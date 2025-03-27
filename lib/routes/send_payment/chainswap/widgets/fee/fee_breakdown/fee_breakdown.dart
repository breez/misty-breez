import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';

class FeeBreakdown extends StatelessWidget {
  final FeeOption feeOption;
  final int? refundAmountSat;

  const FeeBreakdown({required this.feeOption, super.key, this.refundAmountSat});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    final Object? feeDetails = switch (feeOption) {
      final SendChainSwapFeeOption swapFee => swapFee.preparePayOnchainResponse,
      final RefundFeeOption refundFee => refundFee.prepareRefundResponse,
      _ => null,
    };

    if (feeDetails == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        border: Border.all(
          color: themeData.colorScheme.onSurface.withValues(alpha: .4),
        ),
        color: themeData.customData.surfaceBgColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (feeDetails is PreparePayOnchainResponse) ...<Widget>[
            SenderAmount(amountSat: (feeDetails.receiverAmountSat + feeDetails.totalFeesSat).toInt()),
            BoltzServiceFee(boltzServiceFee: (feeDetails.totalFeesSat - feeDetails.claimFeesSat).toInt()),
            TransactionFee(txFeeSat: feeDetails.claimFeesSat.toInt()),
            RecipientAmount(amountSat: feeDetails.receiverAmountSat.toInt()),
          ] else if (feeDetails is PrepareRefundResponse && refundAmountSat != null) ...<Widget>[
            SenderAmount(amountSat: refundAmountSat!),
            TransactionFee(txFeeSat: feeDetails.txFeeSat.toInt()),
            RecipientAmount(amountSat: refundAmountSat! - (feeDetails.txFeeSat).toInt()),
          ],
        ].expand((Widget widget) sync* {
          yield widget;
          yield const Divider(
            height: 8.0,
            color: Color.fromRGBO(40, 59, 74, 0.5),
            indent: 16.0,
            endIndent: 16.0,
          );
        }).toList()
          ..removeLast(),
      ),
    );
  }
}
