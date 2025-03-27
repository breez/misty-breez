import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('SendChainSwapConfirmationPage');

class SendChainSwapConfirmationPage extends StatefulWidget {
  final int amountSat;
  final String onchainRecipientAddress;
  final bool isDrain;

  const SendChainSwapConfirmationPage({
    required this.amountSat,
    required this.onchainRecipientAddress,
    required this.isDrain,
    super.key,
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
    final BreezTranslations texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.sweep_all_coins_speed),
      ),
      body: FutureBuilder<List<SendChainSwapFeeOption>>(
        future: _fetchFeeOptionsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<SendChainSwapFeeOption>> snapshot) {
          if (snapshot.error != null) {
            _logger.severe('Error fetching send chain swap fee options: ${snapshot.error}');
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
              onSelect: (int index) => setState(() {
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
                    preparePayOnchainResponse: affordableFees[selectedFeeIndex].preparePayOnchainResponse,
                  ),
                )
              : null,
    );
  }

  void _fetchSendChainSwapFeeOptions() {
    final ChainSwapCubit chainSwapCubit = context.read<ChainSwapCubit>();
    _fetchFeeOptionsFuture = chainSwapCubit.fetchSendChainSwapFeeOptions(
      amountSat: widget.amountSat,
      isDrain: widget.isDrain,
    );
    _fetchFeeOptionsFuture.then(
      (List<SendChainSwapFeeOption> feeOptions) {
        if (mounted) {
          final AccountCubit accountCubit = context.read<AccountCubit>();
          final AccountState accountState = accountCubit.state;
          setState(() {
            affordableFees = feeOptions
                .where(
                  (SendChainSwapFeeOption f) => f.isAffordable(
                    balanceSat: accountState.walletInfo!.balanceSat.toInt(),
                    amountSat: widget.amountSat,
                  ),
                )
                .toList();
            selectedFeeIndex = (affordableFees.length / 2).floor();
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.severe('Error processing send chain swap fee options: $error');
        setState(() {
          affordableFees = <SendChainSwapFeeOption>[];
          selectedFeeIndex = -1;
        });
      },
    );
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
