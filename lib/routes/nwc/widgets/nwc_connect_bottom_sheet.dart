import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

Future<dynamic> showNwcConnectBottomSheet(
  BuildContext context, {
  NwcCubit? nwcCubit,
  NwcConnectionModel? existingConnection,
}) async {
  final ThemeData themeData = Theme.of(context);
  final NwcCubit activeCubit = nwcCubit ?? context.read<NwcCubit>();

  return await showModalBottomSheet(
    context: context,
    backgroundColor: themeData.customData.paymentListBgColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    isScrollControlled: true,
    builder: (BuildContext context) => BlocProvider<NwcCubit>.value(
      value: activeCubit,
      child: NwcConnectBottomSheet(existingConnection: existingConnection),
    ),
  );
}

class NwcConnectBottomSheet extends StatefulWidget {
  final NwcConnectionModel? existingConnection;

  const NwcConnectBottomSheet({this.existingConnection, super.key});

  @override
  State<NwcConnectBottomSheet> createState() => _NwcConnectBottomSheetState();
}

enum _BudgetRenewalType { daily, weekly, monthly, yearly, never, custom }

class _BudgetRenewalOption {
  const _BudgetRenewalOption({required this.type, required this.label, required this.seconds});

  final _BudgetRenewalType type;
  final String label;
  final int seconds;
}

const List<_BudgetRenewalOption> _presetBudgetRenewalOptions = <_BudgetRenewalOption>[
  _BudgetRenewalOption(type: _BudgetRenewalType.daily, label: 'DAILY', seconds: 86400),
  _BudgetRenewalOption(type: _BudgetRenewalType.weekly, label: 'WEEKLY', seconds: 604800),
  _BudgetRenewalOption(type: _BudgetRenewalType.monthly, label: 'MONTHLY', seconds: 2592000),
  _BudgetRenewalOption(type: _BudgetRenewalType.yearly, label: 'YEARLY', seconds: 31536000),
  _BudgetRenewalOption(type: _BudgetRenewalType.never, label: 'NEVER', seconds: 0),
];

class _NwcConnectBottomSheetState extends State<NwcConnectBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _expiryTimeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _connectionString;
  bool _isObscured = true;
  bool _showBudgetFields = false;
  bool _showExpiryFields = false;
  _BudgetRenewalType? _selectedBudgetRenewal = _BudgetRenewalType.daily;
  int? _customResetTimeSec;

  bool get _isEditMode => widget.existingConnection != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final NwcConnectionModel connection = widget.existingConnection!;
      _nameController.text = connection.name;
      if (connection.periodicBudget != null) {
        _maxBudgetController.text = connection.periodicBudget!.maxBudgetSat.toString();
        _selectedBudgetRenewal = _resolveBudgetRenewalType(connection.periodicBudget!.resetTimeSec);
        _showBudgetFields = true;
      }
      if (connection.expiryTimeSec != null) {
        _expiryTimeController.text = connection.expiryTimeSec.toString();
        _showExpiryFields = true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxBudgetController.dispose();
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
    if (_showBudgetFields) {
      final int? maxBudgetSatInt = _maxBudgetController.text.trim().isEmpty
          ? null
          : int.tryParse(_maxBudgetController.text.trim());
      final int? resetTimeSec = _selectedResetTimeSeconds;

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

  Future<void> _editConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? expiryTimeSec = _expiryTimeController.text.trim().isEmpty
        ? null
        : int.tryParse(_expiryTimeController.text.trim());

    PeriodicBudgetRequest? periodicBudgetReq;
    if (_showBudgetFields) {
      final int? maxBudgetSatInt = _maxBudgetController.text.trim().isEmpty
          ? null
          : int.tryParse(_maxBudgetController.text.trim());
      final int? resetTimeSec = _selectedResetTimeSeconds;

      if (maxBudgetSatInt != null && resetTimeSec != null) {
        periodicBudgetReq = PeriodicBudgetRequest(
          maxBudgetSat: BigInt.from(maxBudgetSatInt),
          resetTimeSec: resetTimeSec,
        );
      }
    }

    final bool success = await context.read<NwcCubit>().editConnection(
      name: widget.existingConnection!.name,
      expiryTimeSec: expiryTimeSec,
      periodicBudgetReq: periodicBudgetReq,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
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

  void _toggleBudgetFields() {
    setState(() {
      _showBudgetFields = !_showBudgetFields;
      if (!_showBudgetFields) {
        _maxBudgetController.clear();
        _selectedBudgetRenewal = _BudgetRenewalType.daily;
        _customResetTimeSec = null;
      } else {
        _selectedBudgetRenewal ??= _BudgetRenewalType.daily;
      }
    });
  }

  void _toggleExpiryFields() {
    setState(() {
      _showExpiryFields = !_showExpiryFields;
      if (!_showExpiryFields) {
        _expiryTimeController.clear();
      }
    });
  }

  List<DropdownMenuItem<_BudgetRenewalType>> _buildBudgetRenewalItems() {
    final List<DropdownMenuItem<_BudgetRenewalType>> items = _presetBudgetRenewalOptions
        .map(
          (_BudgetRenewalOption option) =>
              DropdownMenuItem<_BudgetRenewalType>(value: option.type, child: Text(option.label)),
        )
        .toList();

    if (_customResetTimeSec != null &&
        !_presetBudgetRenewalOptions.any((option) => option.seconds == _customResetTimeSec)) {
      items.add(
        DropdownMenuItem<_BudgetRenewalType>(
          value: _BudgetRenewalType.custom,
          child: Text('CUSTOM (${_customResetTimeSec}s)'),
        ),
      );
    }

    return items;
  }

  int? get _selectedResetTimeSeconds {
    if (!_showBudgetFields || _selectedBudgetRenewal == null) {
      return null;
    }
    if (_selectedBudgetRenewal == _BudgetRenewalType.custom) {
      return _customResetTimeSec;
    }
    for (final _BudgetRenewalOption option in _presetBudgetRenewalOptions) {
      if (option.type == _selectedBudgetRenewal) {
        return option.seconds;
      }
    }
    return null;
  }

  _BudgetRenewalType _resolveBudgetRenewalType(int resetTimeSec) {
    for (final _BudgetRenewalOption option in _presetBudgetRenewalOptions) {
      if (option.seconds == resetTimeSec) {
        _customResetTimeSec = null;
        return option.type;
      }
    }
    _customResetTimeSec = resetTimeSec;
    return _BudgetRenewalType.custom;
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
              _BottomSheetTitle(title: _isEditMode ? 'Edit Connection' : 'Connect a new app'),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        autofocus: !_isEditMode,
                        enabled: !_isEditMode,
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
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      if (_showBudgetFields) ...<Widget>[
                        const SizedBox(height: 16.0),
                        Text(
                          'Budget Renewal',
                          style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _maxBudgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Budget amount',
                            hintText: 'Enter Budget in sats',
                            border: const OutlineInputBorder(),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: themeData.colorScheme.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: themeData.colorScheme.error),
                            ),
                          ),
                          validator: (String? value) {
                            final String trimmedValue = value?.trim() ?? '';
                            if (!_showBudgetFields) {
                              return null;
                            }
                            if (trimmedValue.isEmpty) {
                              return 'Enter budget amount';
                            }
                            if (trimmedValue.isNotEmpty && int.tryParse(trimmedValue) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        DropdownButtonFormField<_BudgetRenewalType>(
                          value: _selectedBudgetRenewal,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Reset Interval',
                            hintText: 'Choose how often the budget renews',
                            border: const OutlineInputBorder(),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: themeData.colorScheme.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: themeData.colorScheme.error),
                            ),
                          ),
                          items: _buildBudgetRenewalItems(),
                          onChanged: (_BudgetRenewalType? value) {
                            setState(() {
                              _selectedBudgetRenewal = value;
                              if (value != _BudgetRenewalType.custom) {
                                _customResetTimeSec = null;
                              }
                            });
                          },
                          validator: (_) {
                            if (!_showBudgetFields) {
                              return null;
                            }
                            if (_maxBudgetController.text.trim().isEmpty) {
                              return 'Enter budget amount first';
                            }
                            final int? resetTime = _selectedResetTimeSeconds;
                            if (resetTime == null) {
                              return 'Select reset time';
                            }
                            final String expiryTimeValue = _expiryTimeController.text.trim();
                            if (expiryTimeValue.isNotEmpty) {
                              final int? expiryTime = int.tryParse(expiryTimeValue);
                              if (expiryTime != null && resetTime > expiryTime) {
                                return 'Reset time cannot be greater than expiry time';
                              }
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                      ],
                      if (_showExpiryFields) ...<Widget>[
                        const SizedBox(height: 16.0),
                        Text(
                          'Connection Expiration',
                          style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _expiryTimeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Expiry Time',
                            hintText: 'Enter Time in seconds',
                            border: const OutlineInputBorder(),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: themeData.colorScheme.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: themeData.colorScheme.error),
                            ),
                          ),
                          validator: (String? value) {
                            final String trimmedValue = value?.trim() ?? '';
                            final int? resetTime = _selectedResetTimeSeconds;

                            if (trimmedValue.isNotEmpty && int.tryParse(trimmedValue) == null) {
                              return 'Please enter a valid number';
                            }

                            if (trimmedValue.isNotEmpty && resetTime != null && _showBudgetFields) {
                              final int? expiryTime = int.tryParse(trimmedValue);
                              if (expiryTime != null && resetTime > expiryTime) {
                                return 'Expiry time must be greater than reset time';
                              }
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          icon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              _showBudgetFields ? Icons.remove_circle_outline : Icons.add_circle_outline,
                              size: 20.0,
                            ),
                          ),
                          label: const Text('BUDGET'),
                          onPressed: _toggleBudgetFields,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48.0),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          ),
                          icon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              _showExpiryFields ? Icons.remove_circle_outline : Icons.add_circle_outline,
                              size: 20.0,
                            ),
                          ),
                          label: const Text('EXPIRY'),
                          onPressed: _toggleExpiryFields,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              BlocBuilder<NwcCubit, NwcState>(
                builder: (BuildContext context, NwcState state) {
                  return Align(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: SingleButtonBottomBar(
                        text: _isEditMode ? 'SAVE' : 'CONNECT',
                        loading: state.isLoading,
                        expand: true,
                        onPressed: _isEditMode ? _editConnection : _createConnection,
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
