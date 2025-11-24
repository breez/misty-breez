import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/receive_payment/widgets/destination_widget/widgets/compact_qr_image.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

class NwcConnectionDetailPage extends StatefulWidget {
  static const String routeName = '/nwc/connection/detail';

  final NwcConnectionModel connection;

  const NwcConnectionDetailPage({required this.connection, super.key});

  @override
  State<NwcConnectionDetailPage> createState() => _NwcConnectionDetailPageState();
}

class _NwcConnectionDetailPageState extends State<NwcConnectionDetailPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _maxBudgetController;
  late TextEditingController _resetTimeController;
  late TextEditingController _expiryTimeController;
  bool _isEditMode = false;
  bool _isSecretVisible = false;
  late NwcConnectionModel _connection;

  @override
  void initState() {
    super.initState();
    _connection = widget.connection;
    _maxBudgetController = TextEditingController(text: '');
    _resetTimeController = TextEditingController(text: '');
    _expiryTimeController = TextEditingController(text: '');
    _populateFormFieldsFromConnection();
  }

  @override
  void dispose() {
    _maxBudgetController.dispose();
    _resetTimeController.dispose();
    _expiryTimeController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _populateFormFieldsFromConnection();
      }
    });
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    final bool success = await context.read<NwcCubit>().editConnection(
      name: _connection.name,
      expiryTimeSec: expiryTimeSec,
      periodicBudgetReq: periodicBudgetReq,
    );

    if (success && mounted) {
      await context.read<NwcCubit>().loadConnections();
      setState(() {
        _isEditMode = false;
      });
      if (mounted) {
        showFlushbar(
          context,
          message: 'Connection updated successfully',
          duration: const Duration(seconds: 3),
        );
      }
    } else if (mounted) {
      showFlushbar(context, message: 'Failed to update connection', duration: const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return BlocListener<NwcCubit, NwcState>(
      listenWhen: (NwcState previous, NwcState current) {
        return previous.isLoading && !current.isLoading && !_isEditMode && current.connections.isNotEmpty;
      },
      listener: (BuildContext context, NwcState state) {
        final NwcConnectionModel updatedConnection = state.connections.firstWhere(
          (NwcConnectionModel c) => c.name == _connection.name,
          orElse: () => _connection,
        );
        setState(() {
          _connection = updatedConnection;
          _populateFormFieldsFromConnection();
        });
      },
      child: Scaffold(
        appBar: AppBar(leading: const back_button.BackButton(), title: Text(_connection.name)),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeData.customData.surfaceBgColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: StatusItem(label: 'Connection Name', value: _connection.name),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeData.customData.surfaceBgColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Connection URI',
                          style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        if (_isSecretVisible)
                          SelectableText(
                            _connection.connectionString,
                            style: themeData.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const SizedBox(height: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSecretVisible = !_isSecretVisible;
                                  });
                                },
                                child: Text(
                                  _isSecretVisible ? 'Hide Connection Secret' : 'Show Connection Secret',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon'), size: 20.0),
                                label: const Text('Copy Connection Secret'),
                                onPressed: () => _copyConnectionString(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showQRDialog(context),
                                child: const Text('Show QR'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeData.customData.surfaceBgColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Periodic Balance',
                            style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _maxBudgetController,
                            keyboardType: TextInputType.number,
                            enabled: _isEditMode,
                            decoration: InputDecoration(
                              labelText: 'Max Budget (sats)',
                              border: const OutlineInputBorder(),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              disabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
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
                            enabled: _isEditMode,
                            decoration: InputDecoration(
                              labelText: 'Reset Time (seconds)',
                              border: const OutlineInputBorder(),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              disabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
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
                          Text(
                            'Expiry',
                            style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _expiryTimeController,
                            keyboardType: TextInputType.number,
                            enabled: _isEditMode,
                            decoration: InputDecoration(
                              labelText: 'Expiry Time (seconds)',
                              border: const OutlineInputBorder(),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              disabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
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
                          BlocBuilder<NwcCubit, NwcState>(
                            builder: (BuildContext context, NwcState state) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: SingleButtonBottomBar(
                                  text: _isEditMode ? 'SAVE' : 'EDIT',
                                  expand: true,
                                  loading: state.isLoading,
                                  onPressed: _isEditMode ? _saveConnection : _toggleEditMode,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyConnectionString(BuildContext context) {
    ServiceInjector().deviceClient.setClipboardText(_connection.connectionString);
    showFlushbar(context, message: 'Connection code copied', duration: const Duration(seconds: 3));
  }

  void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Size screenSize = MediaQuery.of(context).size;
        final double qrSize = screenSize.width * 0.8;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).customData.surfaceBgColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: CompactQRImage(data: _connection.connectionString, size: qrSize),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _populateFormFieldsFromConnection() {
    _maxBudgetController.text = _connection.periodicBudget?.maxBudgetSat.toString() ?? '';
    _resetTimeController.text = _connection.periodicBudget?.resetTimeSec.toString() ?? '';
    _expiryTimeController.text = _connection.expiryTimeSec?.toString() ?? '';
  }
}
