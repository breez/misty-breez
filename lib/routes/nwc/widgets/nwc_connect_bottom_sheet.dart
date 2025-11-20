import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/cubit/nwc/nwc_state.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

Future<dynamic> showNwcConnectBottomSheet(BuildContext context, {NwcCubit? nwcCubit}) async {
  final ThemeData themeData = Theme.of(context);
  return await showModalBottomSheet(
    context: context,
    backgroundColor: themeData.customData.paymentListBgColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    isScrollControlled: true,
    builder: (BuildContext context) {
      if (nwcCubit != null) {
        return BlocProvider<NwcCubit>.value(value: nwcCubit, child: const NwcConnectBottomSheet());
      }
      return BlocProvider<NwcCubit>(
        create: (BuildContext context) => NwcCubit(ServiceInjector().breezSdkLiquid),
        child: const NwcConnectBottomSheet(),
      );
    },
  );
}

class NwcConnectBottomSheet extends StatefulWidget {
  const NwcConnectBottomSheet({super.key});

  @override
  State<NwcConnectBottomSheet> createState() => _NwcConnectBottomSheetState();
}

class _NwcConnectBottomSheetState extends State<NwcConnectBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _resetTimeController = TextEditingController();
  final TextEditingController _expiryTimeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _connectionString;
  bool _isObscured = true;

  @override
  void dispose() {
    _nameController.dispose();
    _maxBudgetController.dispose();
    _resetTimeController.dispose();
    _expiryTimeController.dispose();
    super.dispose();
  }

  Future<void> _createConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final int? expiryTimeSec = _expiryTimeController.text.trim().isEmpty
        ? null
        : int.tryParse(_expiryTimeController.text.trim());

    PeriodicBudgetRequest? periodicBudgetReq;
    if (_maxBudgetController.text.trim().isNotEmpty || _resetTimeController.text.trim().isNotEmpty) {
      final int? maxBudgetSatInt = _maxBudgetController.text.trim().isEmpty
          ? null
          : int.tryParse(_maxBudgetController.text.trim());
      final int? resetTimeSec = _resetTimeController.text.trim().isEmpty
          ? null
          : int.tryParse(_resetTimeController.text.trim());

      if (maxBudgetSatInt != null && resetTimeSec != null) {
        periodicBudgetReq = PeriodicBudgetRequest(
          maxBudgetSat: BigInt.from(maxBudgetSatInt),
          resetTimeSec: resetTimeSec,
        );
      }
    }

    final String? connectionString = await context.read<NwcCubit>().createConnection(
      name: name,
      expiryTimeSec: expiryTimeSec,
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

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _BottomSheetHandle(),
            if (_connectionString == null) ...<Widget>[
              const _BottomSheetTitle(title: 'Connect a new app'),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Name of the app or purpose of the connection',
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Periodic Balance',
                        style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _maxBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Budget (sats)',
                          hintText: 'Optional',
                          border: const OutlineInputBorder(),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                        ),
                        validator: (String? value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              int.tryParse(value.trim()) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _resetTimeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Reset Time (seconds)',
                          hintText: 'Optional',
                          border: const OutlineInputBorder(),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                        ),
                        validator: (String? value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              int.tryParse(value.trim()) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Expiry', style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _expiryTimeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Expiry Time (seconds)',
                          hintText: 'Optional',
                          border: const OutlineInputBorder(),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                        ),
                        validator: (String? value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              int.tryParse(value.trim()) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
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
              const _BottomSheetTitle(title: 'Connection Secret:'),
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
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: CompactQRImage(data: _connectionString!),
                          ),
                        ),
                      ),
                      if (_isObscured)
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.32))),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon'), size: 20.0),
                        label: const Text('Copy Connection Secret'),
                        onPressed: _copyConnectionString,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_isObscured)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscured = true;
                            });
                          },
                          child: const Text('HIDE QR'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Handle at the top of the bottom sheet
class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        margin: const EdgeInsets.only(top: 8.0),
        width: 40.0,
        height: 6.5,
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(50)),
      ),
    );
  }
}

/// Title display for the bottom sheet
class _BottomSheetTitle extends StatelessWidget {
  final String title;

  const _BottomSheetTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: themeData.primaryTextTheme.headlineMedium!.copyWith(fontSize: 18.0, color: Colors.white),
        textAlign: TextAlign.left,
      ),
    );
  }
}
