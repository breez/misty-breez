import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_breakdown/fee_breakdown.dart';
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
  bool isAffordable = false;
  PreparePayOnchainResponse? feeOption;

  late Future<PreparePayOnchainResponse> _preparePayOnchainResponseFuture;

  @override
  void initState() {
    super.initState();
    _preparePayOnchainResponse();
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.csv_exporter_fee),
      ),
      body: FutureBuilder(
        future: _preparePayOnchainResponseFuture,
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

          if (isAffordable) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 40.0),
              child: FeeBreakdown(feeOption: snapshot.data!),
            );
          } else {
            return _ErrorMessage(message: texts.reverse_swap_confirmation_error_funds_fee);
          }
        },
      ),
      bottomNavigationBar: (isAffordable)
          ? SafeArea(
              child: SendChainSwapButton(
                recipientAddress: widget.onchainRecipientAddress,
                preparePayOnchainResponse: feeOption!,
              ),
            )
          : null,
    );
  }

  void _preparePayOnchainResponse() {
    final chainSwapCubit = context.read<ChainSwapCubit>();
    final preparePayOnchainRequest = PreparePayOnchainRequest(
      receiverAmountSat: BigInt.from(widget.amountSat),
    );
    _preparePayOnchainResponseFuture = chainSwapCubit.preparePayOnchain(
      req: preparePayOnchainRequest,
    );
    _preparePayOnchainResponseFuture.then((feeOption) {
      final accountState = context.read<AccountCubit>().state;
      setState(() {
        this.feeOption = feeOption;
        isAffordable = feeOption.isAffordable(balance: accountState.balance);
      });
    }, onError: (error, stackTrace) {
      setState(() {
        isAffordable = false;
        feeOption = null;
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
