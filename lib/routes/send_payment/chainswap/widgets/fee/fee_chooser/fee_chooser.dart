import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';

class FeeChooser extends StatefulWidget {
  final int amountSat;
  final List<FeeOption> feeOptions;
  final int selectedFeeIndex;
  final Function(int) onSelect;

  const FeeChooser({
    required this.amountSat,
    required this.feeOptions,
    required this.selectedFeeIndex,
    required this.onSelect,
    super.key,
  });

  @override
  State<FeeChooser> createState() => _FeeChooserState();
}

class _FeeChooserState extends State<FeeChooser> {
  @override
  Widget build(BuildContext context) {
    final FeeOption selectedFeeOption = widget.feeOptions.elementAt(widget.selectedFeeIndex);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FeeChooserHeader(
            amountSat: widget.amountSat,
            feeOptions: widget.feeOptions,
            selectedFeeIndex: widget.selectedFeeIndex,
            onSelect: (int index) => widget.onSelect(index),
          ),
          const SizedBox(height: 8.0),
          ProcessingSpeedWaitTime(selectedFeeOption.processingSpeed.waitingTime),
          const SizedBox(height: 8.0 + 16.0),
          FeeBreakdown(feeOption: selectedFeeOption, refundAmountSat: widget.amountSat),
        ],
      ),
    );
  }
}
