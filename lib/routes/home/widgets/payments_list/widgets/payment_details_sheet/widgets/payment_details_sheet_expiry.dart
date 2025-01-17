import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:l_breez/utils/date.dart';

enum BlockchainType {
  bitcoin,
  liquid,
}

class PaymentDetailsSheetExpiry extends StatelessWidget {
  final int expiryBlockheight;
  final AutoSizeGroup? labelAutoSizeGroup;
  final BlockchainType chain;

  const PaymentDetailsSheetExpiry({
    required this.expiryBlockheight,
    required this.chain,
    super.key,
    this.labelAutoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (BuildContext context, AccountState accountState) {
        final int? currentTip = chain == BlockchainType.bitcoin
            ? accountState.blockchainInfo?.bitcoinTip
            : accountState.blockchainInfo?.liquidTip;

        final DateTime expiryDate = (chain == BlockchainType.bitcoin
                ? BreezDateUtils.bitcoinBlockDiffToDate(
                    blockHeight: currentTip,
                    expiryBlock: expiryBlockheight,
                  )
                : BreezDateUtils.liquidBlockDiffToDate(
                    blockHeight: currentTip,
                    expiryBlock: expiryBlockheight,
                  )) ??
            DateTime.now();

        return Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: AutoSizeText(
                '${texts.payment_details_dialog_expiration}:',
                style: themeData.primaryTextTheme.headlineMedium?.copyWith(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
                textAlign: TextAlign.left,
                maxLines: 1,
                group: labelAutoSizeGroup,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  BreezDateUtils.formatYearMonthDayHourMinute(expiryDate),
                  style: themeData.primaryTextTheme.displaySmall!.copyWith(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
