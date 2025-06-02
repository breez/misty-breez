import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('RefundConfirmationPage');

class RefundConfirmationPage extends StatefulWidget {
  final RefundParams refundParams;

  const RefundConfirmationPage({required this.refundParams, super.key});

  @override
  State<RefundConfirmationPage> createState() => _RefundConfirmationPageState();
}

class _RefundConfirmationPageState extends State<RefundConfirmationPage> {
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
      appBar: AppBar(title: Text(texts.sweep_all_coins_speed)),
      body: FutureBuilder<List<RefundFeeOption>>(
        future: _fetchFeeOptionsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<RefundFeeOption>> snapshot) {
          if (snapshot.error != null) {
            _logger.severe('Error fetching refund fee options: ${snapshot.error}');
            return _ErrorMessage(
              message: (snapshot.error is PaymentError_InsufficientFunds)
                  ? texts.reverse_swap_confirmation_error_funds_fee
                  : texts.sweep_all_coins_error_retrieve_fees,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Loader());
          }

          if (affordableFees.isNotEmpty) {
            return FeeChooser(
              amountSat: widget.refundParams.refundAmountSat,
              feeOptions: snapshot.data!,
              selectedFeeIndex: selectedFeeIndex,
              onSelect: (int index) => setState(() {
                selectedFeeIndex = index;
              }),
            );
          } else {
            return _ErrorMessage(message: texts.sweep_all_coins_error_amount_small);
          }
        },
      ),
      bottomNavigationBar:
          (affordableFees.isNotEmpty && selectedFeeIndex >= 0 && selectedFeeIndex < affordableFees.length)
          ? SafeArea(
              child: RefundConfirmationButton(
                req: RefundRequest(
                  feeRateSatPerVbyte: affordableFees[selectedFeeIndex].feeRateSatPerVbyte.toInt(),
                  refundAddress: widget.refundParams.toAddress,
                  swapAddress: widget.refundParams.swapAddress,
                ),
              ),
            )
          : null,
    );
  }

  void _fetchRefundFeeOptions() {
    final RefundCubit refundCubit = context.read<RefundCubit>();
    _fetchFeeOptionsFuture = refundCubit.fetchRefundFeeOptions(params: widget.refundParams);
    _fetchFeeOptionsFuture.then(
      (List<RefundFeeOption> feeOptions) {
        if (mounted) {
          setState(() {
            affordableFees = feeOptions
                .where((RefundFeeOption f) => f.isAffordable(balanceSat: widget.refundParams.refundAmountSat))
                .toList();
            selectedFeeIndex = (affordableFees.length / 2).floor();
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.severe('Error processing refund fee options: $error');
        setState(() {
          affordableFees = <RefundFeeOption>[];
          selectedFeeIndex = -1;
        });
      },
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
