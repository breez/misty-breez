import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_chooser/fee_chooser.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_option.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_button.dart';
import 'package:l_breez/widgets/loader.dart';

class SendChainSwapConfirmationPage extends StatefulWidget {
  final int amountSat;
  final String onchainRecipientAddress;
  final bool isMaxValue;

  const SendChainSwapConfirmationPage({
    super.key,
    required this.amountSat,
    required this.onchainRecipientAddress,
    required this.isMaxValue,
  });

  @override
  State<SendChainSwapConfirmationPage> createState() => _SendChainSwapConfirmationPageState();
}

class _SendChainSwapConfirmationPageState extends State<SendChainSwapConfirmationPage> {
  List<SendChainSwapFeeOption> affordableFees = <SendChainSwapFeeOption>[];
  int selectedFeeIndex = -1;

  late Future<List<SendChainSwapFeeOption>> _fetchFeeOptionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchSendChainSwapFeeOptions();
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.sweep_all_coins_speed),
      ),
      body: FutureBuilder(
        future: _fetchFeeOptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.error != null) {
            return _ErrorMessage(
              message: (snapshot.error is PaymentError_InsufficientFunds)
                  ? texts.reverse_swap_confirmation_error_funds_fee
                  : texts.reverse_swap_confirmation_error_fetch_fee,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Loader());
          }

          if (affordableFees.isNotEmpty) {
            return FeeChooser(
              amountSat: widget.amountSat,
              feeOptions: snapshot.data!,
              selectedFeeIndex: selectedFeeIndex,
              onSelect: (index) => setState(() {
                selectedFeeIndex = index;
              }),
            );
          } else {
            return _ErrorMessage(message: texts.reverse_swap_confirmation_error_funds_fee);
          }
        },
      ),
      bottomNavigationBar:
          (affordableFees.isNotEmpty && selectedFeeIndex >= 0 && selectedFeeIndex < affordableFees.length)
              ? SafeArea(
                  child: SendChainSwapButton(
                    recipientAddress: widget.onchainRecipientAddress,
                    preparePayOnchainResponse: affordableFees[selectedFeeIndex].pairInfo,
                  ),
                )
              : null,
    );
  }

  void _fetchSendChainSwapFeeOptions() {
    final chainSwapCubit = context.read<ChainSwapCubit>();
    _fetchFeeOptionsFuture = chainSwapCubit.fetchSendChainSwapFeeOptions(
      amountSat: widget.amountSat,
    );
    _fetchFeeOptionsFuture.then((feeOptions) {
      if (mounted) {
        final accountCubit = context.read<AccountCubit>();
        final accountState = accountCubit.state;
        setState(() {
          affordableFees = feeOptions
              .where((f) => f.isAffordable(balanceSat: accountState.balance, amountSat: widget.amountSat))
              .toList();
          selectedFeeIndex = (affordableFees.length / 2).floor();
        });
      }
    }, onError: (error, stackTrace) {
      setState(() {
        affordableFees = <SendChainSwapFeeOption>[];
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
