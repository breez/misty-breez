import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';

class FeeChooserHeader extends StatefulWidget {
  final int amountSat;
  final List<FeeOption> feeOptions;
  final int selectedFeeIndex;
  final Function(int) onSelect;

  const FeeChooserHeader({
    required this.amountSat,
    required this.feeOptions,
    required this.selectedFeeIndex,
    required this.onSelect,
    super.key,
  });

  @override
  State<FeeChooserHeader> createState() => _FeeChooserHeaderState();
}

class _FeeChooserHeaderState extends State<FeeChooserHeader> {
  late List<FeeOptionButton> feeOptionButtons;

  @override
  Widget build(BuildContext context) {
    final AccountCubit accountCubit = context.read<AccountCubit>();
    final AccountState accountState = accountCubit.state;
    final BreezTranslations texts = context.texts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: List<FeeOptionButton>.generate(widget.feeOptions.length, (int index) {
            final FeeOption feeOption = widget.feeOptions.elementAt(index);

            final int feeCoverageSat = switch (feeOption) {
              RefundFeeOption() => widget.amountSat,
              _ => accountState.walletInfo!.balanceSat.toInt(),
            };

            return FeeOptionButton(
              index: index,
              text: feeOption.getDisplayName(texts),
              isAffordable: feeOption.isAffordable(feeCoverageSat: feeCoverageSat),
              isSelected: widget.selectedFeeIndex == index,
              onSelect: () => widget.onSelect(index),
            );
          }),
        ),
      ],
    );
  }
}
