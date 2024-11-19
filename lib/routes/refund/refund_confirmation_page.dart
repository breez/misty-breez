import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_chooser/fee_chooser.dart';
import 'package:l_breez/routes/refund/widgets/widgets.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class RefundConfirmationPage extends StatefulWidget {
  final int amountSat;
  final String swapAddress;
  final String toAddress;
  final String? originalTransaction;

  const RefundConfirmationPage({
    required this.amountSat,
    required this.toAddress,
    required this.swapAddress,
    super.key,
    this.originalTransaction,
  });

  @override
  State<StatefulWidget> createState() {
    return RefundConfirmationState();
  }
}

class RefundConfirmationState extends State<RefundConfirmationPage> {
  List<RefundFeeOption> affordableFees = <RefundFeeOption>[];
  int selectedFeeIndex = -1;

  late Future<List<RefundFeeOption>> _fetchFeeOptionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchRefundFeeOptions();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.sweep_all_coins_speed),
      ),
      body: FutureBuilder<List<RefundFeeOption>>(
        future: _fetchFeeOptionsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<RefundFeeOption>> snapshot) {
          if (snapshot.error != null) {
            return _ErrorMessage(
              message: texts.sweep_all_coins_error_retrieve_fees,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Loader(
                color: Colors.white,
              ),
            );
          }

          if (affordableFees.isNotEmpty) {
            return FeeChooser(
              amountSat: widget.amountSat,
              feeOptions: snapshot.data!,
              selectedFeeIndex: selectedFeeIndex,
              onSelect: (int index) => setState(() {
                selectedFeeIndex = index;
              }),
            );
          } else {
            return _ErrorMessage(
              message: texts.sweep_all_coins_error_amount_small,
            );
          }
        },
      ),
      bottomNavigationBar:
          (affordableFees.isNotEmpty && selectedFeeIndex >= 0 && selectedFeeIndex < affordableFees.length)
              ? RefundButton(
                  req: RefundRequest(
                    feeRateSatPerVbyte: affordableFees[selectedFeeIndex].feeRateSatPerVbyte.toInt(),
                    refundAddress: widget.toAddress,
                    swapAddress: widget.swapAddress,
                  ),
                )
              : SingleButtonBottomBar(
                  text: texts.sweep_all_coins_action_retry,
                  onPressed: () => _fetchRefundFeeOptions,
                  stickToBottom: true,
                ),
    );
  }

  void _fetchRefundFeeOptions() {
    final RefundCubit refundCubit = context.read<RefundCubit>();
    _fetchFeeOptionsFuture = refundCubit.fetchRefundFeeOptions(
      toAddress: widget.toAddress,
      swapAddress: widget.swapAddress,
    );
    _fetchFeeOptionsFuture.then((List<RefundFeeOption> feeOptions) {
      setState(() {
        affordableFees = feeOptions
            .where(
              (RefundFeeOption f) => f.isAffordable(amountSat: widget.amountSat),
            )
            .toList();
        selectedFeeIndex = (affordableFees.length / 2).floor();
      });
    });
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
