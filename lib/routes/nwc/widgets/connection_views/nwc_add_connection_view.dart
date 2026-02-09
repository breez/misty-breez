import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class NwcAddConnectionView extends StatefulWidget {
  final VoidCallback? onConnectionCreated;

  const NwcAddConnectionView({super.key, this.onConnectionCreated});

  @override
  State<NwcAddConnectionView> createState() => NwcAddConnectionViewState();
}

class NwcAddConnectionViewState extends State<NwcAddConnectionView> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AutoSizeGroup _buttonTextGroup = AutoSizeGroup();
  String? _connectionString;
  bool _isObscured = true;

  int? _maxBudgetSat;
  int? _renewalIntervalMins;
  int? _expirationTimeMins;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> createConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final int? expirationTimeMins = _expirationTimeMins;

    PeriodicBudgetRequest? periodicBudgetReq;
    final int? maxBudgetSatInt = _maxBudgetSat;
    final int? renewalIntervalMins = _renewalIntervalMins;

    if (maxBudgetSatInt != null) {
      if (renewalIntervalMins != null && renewalIntervalMins > 0) {
        periodicBudgetReq = PeriodicBudgetRequest(
          maxBudgetSat: BigInt.from(maxBudgetSatInt),
          renewalTimeMins: renewalIntervalMins,
        );
      } else {
        periodicBudgetReq = PeriodicBudgetRequest(maxBudgetSat: BigInt.from(maxBudgetSatInt));
      }
    }

    try {
      final String? connectionString = await context.read<NwcCubit>().createConnection(
        name: name,
        expirationTimeMins: expirationTimeMins,
        periodicBudgetReq: periodicBudgetReq,
      );

      if (connectionString != null && mounted) {
        setState(() {
          _connectionString = connectionString;
        });
        widget.onConnectionCreated?.call();
      } else if (mounted) {
        final String? error = context.read<NwcCubit>().state.error;
        showFlushbar(
          context,
          message: error != null
              ? ExceptionHandler.extractMessage(error, context.texts())
              : 'Failed to create connection',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        showFlushbar(
          context,
          message: 'Failed to create connection: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _copyConnectionString() {
    if (_connectionString != null) {
      ServiceInjector().deviceClient.setClipboardText(_connectionString!);
      showFlushbar(context, message: 'Connection code copied', duration: const Duration(seconds: 3));
    }
  }

  void _shareConnectionString() {
    if (_connectionString != null) {
      final ShareParams shareParams = ShareParams(text: _connectionString!);
      SharePlus.instance.share(shareParams);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionString == null) {
      return Container(
        decoration: ShapeDecoration(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          color: Theme.of(context).customData.surfaceBgColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: NwcConnectionForm(
          formKey: _formKey,
          nameController: _nameController,
          isEditMode: false,
          onValuesChanged: (int? maxBudgetSat, int? renewalIntervalMins, int? expirationTimeMins) {
            setState(() {
              _maxBudgetSat = maxBudgetSat;
              _renewalIntervalMins = renewalIntervalMins;
              _expirationTimeMins = expirationTimeMins;
            });
          },
        ),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(begin: _isObscured ? 14.0 : 0.0, end: _isObscured ? 14.0 : 0.0),
                  builder: (BuildContext context, double blurValue, Widget? child) {
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                      child: child,
                    );
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      width: 230.0,
                      height: 230.0,
                      clipBehavior: Clip.antiAlias,
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                      ),
                      child: CompactQRImage(data: _connectionString!),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isObscured ? 1.0 : 0.0,
                  child: Container(color: Colors.black.withValues(alpha: .32)),
                ),
                if (_isObscured)
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _isObscured = false;
                      });
                    },
                    child: const Text('SHOW QR'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: 24.0,
              bottom: MediaQuery.of(context).viewPadding.bottom + 24.0,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0, minWidth: 138.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon'), size: 20.0),
                      label: AutoSizeText(
                        'COPY',
                        style: balanceFiatConversionTextStyle,
                        maxLines: 1,
                        group: _buttonTextGroup,
                        minFontSize: MinFontSize(context).minFontSize,
                        stepGranularity: 0.1,
                      ),
                      onPressed: _copyConnectionString,
                    ),
                  ),
                ),
                const SizedBox(width: 32.0),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0, minWidth: 138.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(IconData(0xe917, fontFamily: 'icomoon'), size: 20.0),
                      label: AutoSizeText(
                        'SHARE',
                        style: balanceFiatConversionTextStyle,
                        maxLines: 1,
                        group: _buttonTextGroup,
                        minFontSize: MinFontSize(context).minFontSize,
                        stepGranularity: 0.1,
                      ),
                      onPressed: _shareConnectionString,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
