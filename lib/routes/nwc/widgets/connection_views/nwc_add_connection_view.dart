import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class NwcAddConnectionView extends StatefulWidget {
  const NwcAddConnectionView({super.key});

  @override
  State<NwcAddConnectionView> createState() => _NwcAddConnectionViewState();
}

class _NwcAddConnectionViewState extends State<NwcAddConnectionView> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _connectionString;
  bool _isObscured = true;

  int? _maxBudgetSat;
  int? _renewalTimeMins;
  int? _expiryTimeMins;
  bool _showBudgetFields = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final int? expiryTimeMins = _expiryTimeMins;

    PeriodicBudgetRequest? periodicBudgetReq;
    if (_showBudgetFields) {
      final int? maxBudgetSatInt = _maxBudgetSat;
      final int? renewalTimeMins = _renewalTimeMins;

      if (maxBudgetSatInt != null) {
        if (renewalTimeMins != null && renewalTimeMins > 0) {
          periodicBudgetReq = PeriodicBudgetRequest(
            maxBudgetSat: BigInt.from(maxBudgetSatInt),
            renewalTimeMins: renewalTimeMins,
          );
        } else {
          periodicBudgetReq = PeriodicBudgetRequest(maxBudgetSat: BigInt.from(maxBudgetSatInt));
        }
      }
    }

    final String? connectionString = await context.read<NwcCubit>().createConnection(
      name: name,
      expiryTimeMins: expiryTimeMins,
      periodicBudgetReq: periodicBudgetReq,
    );

    if (connectionString != null && mounted) {
      setState(() {
        _connectionString = connectionString;
      });
    } else if (mounted) {
      showFlushbar(context, message: 'Failed to create connection', duration: const Duration(seconds: 3));
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const BottomSheetHandle(),
        if (_connectionString == null) ...<Widget>[
          const BottomSheetTitle(title: 'Connect a new app'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: NwcConnectionForm(
              formKey: _formKey,
              nameController: _nameController,
              isEditMode: false,
              onValuesChanged:
                  (
                    int? maxBudgetSat,
                    int? renewalTimeMins,
                    int? expiryTimeMins,
                    bool showBudgetFields,
                    bool showExpiryFields,
                  ) {
                    setState(() {
                      _maxBudgetSat = maxBudgetSat;
                      _renewalTimeMins = renewalTimeMins;
                      _expiryTimeMins = expiryTimeMins;
                      _showBudgetFields = showBudgetFields;
                    });
                  },
            ),
          ),
          BlocBuilder<NwcCubit, NwcState>(
            builder: (BuildContext context, NwcState state) {
              return Align(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: SingleButtonBottomBar(
                    text: 'CONNECT',
                    loading: state.isLoading,
                    expand: true,
                    onPressed: _createConnection,
                  ),
                ),
              );
            },
          ),
        ] else ...<Widget>[
          const BottomSheetTitle(title: 'Connection Secret:'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: ImageFiltered(
                      imageFilter: _isObscured
                          ? ImageFilter.blur(sigmaX: 14, sigmaY: 14)
                          : ImageFilter.blur(),
                      child: AspectRatio(aspectRatio: 1.0, child: CompactQRImage(data: _connectionString!)),
                    ),
                  ),
                  if (_isObscured)
                    Positioned.fill(child: Container(color: Colors.black.withValues(alpha: .32))),
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
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      ),
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(IconData(0xe90b, fontFamily: 'icomoon'), size: 20.0),
                      ),
                      label: const Text('COPY'),
                      onPressed: _copyConnectionString,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      ),
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(IconData(0xe917, fontFamily: 'icomoon'), size: 20.0),
                      ),
                      label: const Text('SHARE'),
                      onPressed: _shareConnectionString,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
