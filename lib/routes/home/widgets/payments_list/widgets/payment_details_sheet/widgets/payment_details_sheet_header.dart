import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentDetailsSheetHeader extends StatefulWidget {
  final PaymentData paymentData;

  const PaymentDetailsSheetHeader({required this.paymentData, super.key});

  @override
  State<PaymentDetailsSheetHeader> createState() => _PaymentDetailsSheetHeaderState();
}

class _PaymentDetailsSheetHeaderState extends State<PaymentDetailsSheetHeader> {
  Timer? _feesPollingTimer;
  Timer? _uiUpdateTimer;

  // UI-only state
  int _secondsUntilNextUpdate = 60;
  bool _isTimerActive = false;
  bool _isAcceptingFees = false;
  bool _isRejectingFees = false;
  bool _hasProcessedFees = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentData.status == PaymentState.waitingFeeAcceptance) {
      _startFeesPolling();
    }
  }

  @override
  void dispose() {
    _feesPollingTimer?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void _startFeesPolling() {
    final String? swapId = widget.paymentData.swapId;
    if (swapId == null) {
      return;
    }

    // Fetch fees immediately
    context.read<AmountlessBtcCubit>().fetchPaymentProposedFees(swapId);

    // Start UI timer
    _startUiTimer();

    // Poll every minute
    _feesPollingTimer = Timer.periodic(const Duration(minutes: 1), (Timer timer) {
      if (mounted && !_hasProcessedFees && widget.paymentData.status == PaymentState.waitingFeeAcceptance) {
        context.read<AmountlessBtcCubit>().fetchPaymentProposedFees(swapId);
        _resetTimer();
      } else {
        timer.cancel();
        _stopUiTimer();
      }
    });
  }

  void _startUiTimer() {
    _isTimerActive = true;
    _secondsUntilNextUpdate = 60;

    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted && _isTimerActive) {
        setState(() {
          _secondsUntilNextUpdate--;
          if (_secondsUntilNextUpdate <= 0) {
            _secondsUntilNextUpdate = 60;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopUiTimer() {
    _isTimerActive = false;
    _uiUpdateTimer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _secondsUntilNextUpdate = 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Center(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 128,
                  minWidth: 128,
                  maxHeight: 128,
                  maxWidth: 128,
                ),
                child: PaymentItemAvatar(widget.paymentData, radius: 64.0),
              ),
            ),
          ),
          PaymentDetailsSheetContentTitle(paymentData: widget.paymentData),
          PaymentDetailsSheetDescription(paymentData: widget.paymentData),

          if (!_hasProcessedFees &&
              widget.paymentData.status == PaymentState.waitingFeeAcceptance) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Chip(
                label: const Text('Pending Approval'),
                backgroundColor: themeData.customData.pendingTextColor,
              ),
            ),
            _buildFeeAcceptanceCard(),
          ],

          if (widget.paymentData.status == PaymentState.refundPending) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: const Text('Pending Refund'),
                backgroundColor: themeData.customData.pendingTextColor,
              ),
            ),
          ],
          if (widget.paymentData.isRefunded ||
              widget.paymentData.status == PaymentState.refundable) ...<Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Chip(label: Text('FAILED'), backgroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeAcceptanceCard() {
    final ThemeData themeData = Theme.of(context);

    final String? swapId = widget.paymentData.swapId;
    if (swapId == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<AmountlessBtcCubit, AmountlessBtcState>(
      builder: (BuildContext context, AmountlessBtcState state) {
        final FetchPaymentProposedFeesResponse? proposedFees = state.proposedFeesMap[swapId];

        return Card(
          color: themeData.customData.surfaceBgColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (proposedFees != null) ...<Widget>[
                _buildFeeDetails(proposedFees),
              ] else if (state.isLoadingFees) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                    border: Border.all(color: themeData.colorScheme.onSurface.withValues(alpha: .4)),
                    color: themeData.customData.surfaceBgColor,
                  ),
                  child: const Center(
                    child: Column(
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        LoadingAnimatedText(loadingMessage: 'Retrieving fees'),
                      ],
                    ),
                  ),
                ),
              ] else if (state.hasError) ...<Widget>[_buildErrorState(state.error)],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerDisplay() {
    if (!_isTimerActive || _hasProcessedFees) {
      return const SizedBox.shrink();
    }
    final ThemeData themeData = Theme.of(context);
    final double progress = (_secondsUntilNextUpdate / 60.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Center(
              child: AutoSizeText(
                'Expect fee variation depending on network usage.',
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: themeData.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  fontSize: 13.5,
                ),
                minFontSize: MinFontSize(context).minFontSize,
                stepGranularity: 0.1,
                textAlign: TextAlign.left,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  backgroundColor: themeData.colorScheme.onSurface.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(themeData.colorScheme.primary),
                ),
                Text(
                  '$_secondsUntilNextUpdate',
                  style: themeData.textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: themeData.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeDetails(FetchPaymentProposedFeesResponse fees) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        border: Border.all(color: themeData.colorScheme.onSurface.withValues(alpha: .4)),
        color: themeData.customData.surfaceBgColor,
      ),
      child: Column(
        children: <Widget>[
          SenderAmount(title: 'Sent:', amountSat: fees.payerAmountSat.toInt()),
          const Divider(height: 8.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 16.0, endIndent: 16.0),
          TransactionFee(nonTransparent: true, txFeeSat: fees.feesSat.toInt()),
          const Divider(height: 8.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 16.0, endIndent: 16.0),
          RecipientAmount(amountSat: fees.receiverAmountSat.toInt()),
          _buildTimerDisplay(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final ThemeData themeData = Theme.of(context);
    final bool isProcessing = _isAcceptingFees || _isRejectingFees;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: themeData.colorScheme.onSurface.withValues(alpha: .4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isProcessing ? null : () => _rejectFees(),
              label: _isRejectingFees
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('REJECT'),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0.0,
                disabledBackgroundColor: themeData.disabledColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onPressed: isProcessing ? null : () => _acceptFees(),
              child: _isAcceptingFees
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('ACCEPT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<AmountlessBtcCubit, AmountlessBtcState>(
      builder: (BuildContext context, AmountlessBtcState state) {
        final bool isRetrying = state.isLoadingFees;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: isRetrying ? null : () => _retryFetchFees(),
          child: WarningBox(
            boxPadding: EdgeInsets.zero,
            backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
            contentPadding: const EdgeInsets.all(16.0),
            child: isRetrying
                ? const CenteredLoader()
                : RichText(
                    text: TextSpan(
                      text: 'Failed to retrieve fees.',
                      style: themeData.textTheme.bodyLarge?.copyWith(color: themeData.colorScheme.error),
                      children: <InlineSpan>[
                        TextSpan(
                          text: '\n\nTap here to retry',
                          style: themeData.textTheme.titleLarge?.copyWith(
                            color: themeData.colorScheme.error.withValues(alpha: .7),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        );
      },
    );
  }

  Future<void> _acceptFees() async {
    setState(() {
      _isAcceptingFees = true;
      _hasProcessedFees = true;
    });
    _stopUiTimer();

    try {
      await context.read<AmountlessBtcCubit>().acceptPaymentProposedFees(widget.paymentData.swapId!);
      if (mounted) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.settings.name == Home.routeName);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAcceptingFees = false;
        });
      }
    }
  }

  Future<void> _rejectFees() async {
    setState(() {
      _isRejectingFees = true;
      _hasProcessedFees = true;
    });
    _stopUiTimer();

    try {
      context.read<AmountlessBtcCubit>().rejectPaymentProposedFees(widget.paymentData.swapId!);
      if (mounted) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.settings.name == Home.routeName);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRejectingFees = false;
        });
      }
    }
  }

  void _retryFetchFees() {
    context.read<AmountlessBtcCubit>().fetchPaymentProposedFees(widget.paymentData.swapId!);
  }
}
