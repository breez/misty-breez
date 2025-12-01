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
  const _BudgetRenewalOption({required this.type, required this.label, required this.minutes});

  final _BudgetRenewalType type;
  final String label;
  final int minutes;
}

const List<_BudgetRenewalOption> _presetBudgetRenewalOptions = <_BudgetRenewalOption>[
  _BudgetRenewalOption(type: _BudgetRenewalType.daily, label: 'Daily', minutes: 1440),
  _BudgetRenewalOption(type: _BudgetRenewalType.weekly, label: 'Weekly', minutes: 10080),
  _BudgetRenewalOption(type: _BudgetRenewalType.monthly, label: 'Monthly', minutes: 43200),
  _BudgetRenewalOption(type: _BudgetRenewalType.yearly, label: 'Yearly', minutes: 525600),
  _BudgetRenewalOption(type: _BudgetRenewalType.never, label: 'Never', minutes: 0),
];

enum _BudgetAmountOption { tenK, hundredK, oneM, unlimited, custom }

class _BudgetAmountOptionData {
  const _BudgetAmountOptionData({required this.type, required this.label, this.sats});

  final _BudgetAmountOption type;
  final String label;
  final int? sats; // null for unlimited
}

const List<_BudgetAmountOptionData> _presetBudgetAmountOptions = <_BudgetAmountOptionData>[
  _BudgetAmountOptionData(type: _BudgetAmountOption.tenK, label: '10k sats', sats: 10000),
  _BudgetAmountOptionData(type: _BudgetAmountOption.hundredK, label: '100k sats', sats: 100000),
  _BudgetAmountOptionData(type: _BudgetAmountOption.oneM, label: '1M sats', sats: 1000000),
  _BudgetAmountOptionData(type: _BudgetAmountOption.unlimited, label: 'Unlimited', sats: null),
  _BudgetAmountOptionData(type: _BudgetAmountOption.custom, label: 'Custom', sats: null),
];

enum _ExpiryTimeOption { oneWeek, oneMonth, oneYear, never, custom }

class _ExpiryTimeOptionData {
  const _ExpiryTimeOptionData({required this.type, required this.label, this.minutes});

  final _ExpiryTimeOption type;
  final String label;
  final int? minutes; // null for never
}

const List<_ExpiryTimeOptionData> _presetExpiryTimeOptions = <_ExpiryTimeOptionData>[
  _ExpiryTimeOptionData(type: _ExpiryTimeOption.oneWeek, label: '1 week', minutes: 10080),
  _ExpiryTimeOptionData(type: _ExpiryTimeOption.oneMonth, label: '1 month', minutes: 43200),
  _ExpiryTimeOptionData(type: _ExpiryTimeOption.oneYear, label: '1 year', minutes: 525600),
  _ExpiryTimeOptionData(type: _ExpiryTimeOption.never, label: 'Never', minutes: null),
  _ExpiryTimeOptionData(type: _ExpiryTimeOption.custom, label: 'Custom', minutes: null),
];

class _NwcConnectBottomSheetState extends State<NwcConnectBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _expiryTimeController = TextEditingController();
  final TextEditingController _customRenewalTimeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _connectionString;
  bool _isObscured = true;
  bool _showBudgetFields = false;
  bool _showExpiryFields = false;
  _BudgetRenewalType? _selectedBudgetRenewal = _BudgetRenewalType.daily;
  int? _customRenewalTimeMins;
  _BudgetAmountOption? _selectedBudgetAmount;
  _ExpiryTimeOption? _selectedExpiryTime;
  int? _customBudgetAmount;

  bool get _isEditMode => widget.existingConnection != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final NwcConnectionModel connection = widget.existingConnection!;
      _nameController.text = connection.name;
      if (connection.periodicBudget != null) {
        final int maxBudgetSat = connection.periodicBudget!.maxBudgetSat.toInt();
        _selectedBudgetAmount = _resolveBudgetAmountOption(maxBudgetSat);
        if (_selectedBudgetAmount == _BudgetAmountOption.custom) {
          _customBudgetAmount = maxBudgetSat;
          _maxBudgetController.text = maxBudgetSat.toString();
        }
        if (connection.periodicBudget!.renewsAt != null) {
          final int renewalIntervalMins =
              ((connection.periodicBudget!.renewsAt! - connection.periodicBudget!.updatedAt) / 60).round();
          _selectedBudgetRenewal = _resolveBudgetRenewalType(renewalIntervalMins);
          if (_selectedBudgetRenewal == _BudgetRenewalType.custom && _customRenewalTimeMins != null) {
            _customRenewalTimeController.text = _customRenewalTimeMins.toString();
          }
        } else {
          _selectedBudgetRenewal = _BudgetRenewalType.never;
        }
        _showBudgetFields = true;
      } else {
        _showBudgetFields = false;
      }
      if (connection.expiresAt != null) {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final int remainingMins = ((connection.expiresAt! - now) / 60).round();
        if (remainingMins > 0) {
          _selectedExpiryTime = _resolveExpiryTimeOption(remainingMins);
          _showExpiryFields = true;
        } else {
          _selectedExpiryTime = _ExpiryTimeOption.never;
          _showExpiryFields = true;
        }
      } else {
        _selectedExpiryTime = _ExpiryTimeOption.never;
        _showExpiryFields = false;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxBudgetController.dispose();
    _expiryTimeController.dispose();
    _customRenewalTimeController.dispose();
    super.dispose();
  }

  Future<void> _createConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final int? expiryTimeMins = _selectedExpiryTimeMinutes;

    PeriodicBudgetRequest? periodicBudgetReq;
    if (_showBudgetFields) {
      final int? maxBudgetSatInt = _selectedBudgetAmountSats;
      final int? renewalTimeMins = _selectedRenewalTimeMinutes;

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

  Future<void> _editConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? expiryTimeMins;
    final bool? removeExpiry;
    if (!_showExpiryFields) {
      removeExpiry = widget.existingConnection!.expiresAt != null ? true : null;
      expiryTimeMins = null;
    } else if (_selectedExpiryTime == _ExpiryTimeOption.never) {
      removeExpiry = widget.existingConnection!.expiresAt != null ? true : null;
      expiryTimeMins = null;
    } else {
      expiryTimeMins = _selectedExpiryTimeMinutes;
      removeExpiry = null;
    }

    PeriodicBudgetRequest? periodicBudgetReq;
    bool? removePeriodicBudget;
    if (_showBudgetFields) {
      final int? maxBudgetSatInt = _selectedBudgetAmountSats;
      final int? renewalTimeMins = _selectedRenewalTimeMinutes;

      if (maxBudgetSatInt != null) {
        if (renewalTimeMins != null && renewalTimeMins > 0) {
          periodicBudgetReq = PeriodicBudgetRequest(
            maxBudgetSat: BigInt.from(maxBudgetSatInt),
            renewalTimeMins: renewalTimeMins,
          );
        } else {
          periodicBudgetReq = PeriodicBudgetRequest(maxBudgetSat: BigInt.from(maxBudgetSatInt));
        }
      } else {
        if (widget.existingConnection!.periodicBudget != null) {
          removePeriodicBudget = true;
        }
      }
    } else if (widget.existingConnection!.periodicBudget != null) {
      removePeriodicBudget = true;
    }

    final bool success = await context.read<NwcCubit>().editConnection(
      name: widget.existingConnection!.name,
      expiryTimeMins: expiryTimeMins,
      removeExpiry: removeExpiry,
      periodicBudgetReq: periodicBudgetReq,
      removePeriodicBudget: removePeriodicBudget,
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
        _customRenewalTimeMins = null;
        _customRenewalTimeController.clear();
        _selectedBudgetAmount = null;
        _customBudgetAmount = null;
      } else {
        if (widget.existingConnection?.periodicBudget == null) {
          _selectedBudgetAmount = _BudgetAmountOption.unlimited;
          _selectedBudgetRenewal = _BudgetRenewalType.never;
        } else {
          _selectedBudgetRenewal ??= _BudgetRenewalType.daily;
        }
      }
    });
  }

  void _toggleExpiryFields() {
    setState(() {
      _showExpiryFields = !_showExpiryFields;
      if (!_showExpiryFields) {
        _expiryTimeController.clear();
        _selectedExpiryTime = null;
      } else {
        if (widget.existingConnection?.expiresAt == null) {
          _selectedExpiryTime = _ExpiryTimeOption.never;
        }
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

    if (_customRenewalTimeMins != null &&
        !_presetBudgetRenewalOptions.any((option) => option.minutes == _customRenewalTimeMins)) {
      items.add(
        DropdownMenuItem<_BudgetRenewalType>(
          value: _BudgetRenewalType.custom,
          child: Text('CUSTOM (${_customRenewalTimeMins}m)'),
        ),
      );
    }

    return items;
  }

  int? get _selectedRenewalTimeMinutes {
    if (!_showBudgetFields || _selectedBudgetRenewal == null) {
      return null;
    }
    if (_selectedBudgetRenewal == _BudgetRenewalType.custom) {
      if (_customRenewalTimeMins == null) {
        final String trimmedValue = _customRenewalTimeController.text.trim();
        if (trimmedValue.isNotEmpty) {
          return int.tryParse(trimmedValue);
        }
      }
      return _customRenewalTimeMins;
    }
    for (final _BudgetRenewalOption option in _presetBudgetRenewalOptions) {
      if (option.type == _selectedBudgetRenewal) {
        return option.minutes;
      }
    }
    return null;
  }

  _BudgetRenewalType _resolveBudgetRenewalType(int renewalTimeMins) {
    const int toleranceMins = 15;
    for (final _BudgetRenewalOption option in _presetBudgetRenewalOptions) {
      if ((option.minutes - renewalTimeMins).abs() <= toleranceMins) {
        _customRenewalTimeMins = null;
        return option.type;
      }
    }
    _customRenewalTimeMins = renewalTimeMins;
    return _BudgetRenewalType.custom;
  }

  _BudgetAmountOption _resolveBudgetAmountOption(int sats) {
    for (final _BudgetAmountOptionData option in _presetBudgetAmountOptions) {
      if (option.sats == sats) {
        _customBudgetAmount = null;
        return option.type;
      }
    }
    _customBudgetAmount = sats;
    return _BudgetAmountOption.custom;
  }

  _ExpiryTimeOption _resolveExpiryTimeOption(int minutes) {
    for (final _ExpiryTimeOptionData option in _presetExpiryTimeOptions) {
      if (option.minutes == minutes) {
        return option.type;
      }
    }
    if (minutes <= 0) {
      return _ExpiryTimeOption.never;
    }
    return _ExpiryTimeOption.custom;
  }

  int? get _selectedBudgetAmountSats {
    if (!_showBudgetFields || _selectedBudgetAmount == null) {
      return null;
    }
    if (_selectedBudgetAmount == _BudgetAmountOption.unlimited) {
      return null; // Unlimited
    }
    if (_selectedBudgetAmount == _BudgetAmountOption.custom) {
      if (_customBudgetAmount == null) {
        final String trimmedValue = _maxBudgetController.text.trim();
        if (trimmedValue.isNotEmpty) {
          return int.tryParse(trimmedValue);
        }
      }
      return _customBudgetAmount;
    }
    for (final _BudgetAmountOptionData option in _presetBudgetAmountOptions) {
      if (option.type == _selectedBudgetAmount) {
        return option.sats;
      }
    }
    return null;
  }

  int? get _selectedExpiryTimeMinutes {
    if (!_showExpiryFields || _selectedExpiryTime == null) {
      return null;
    }
    if (_selectedExpiryTime == _ExpiryTimeOption.never) {
      return null;
    }
    if (_selectedExpiryTime == _ExpiryTimeOption.custom) {
      // TODO(ayush): Custom not implemented yet
      return null;
    }
    for (final _ExpiryTimeOptionData option in _presetExpiryTimeOptions) {
      if (option.type == _selectedExpiryTime) {
        return option.minutes;
      }
    }
    return null;
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
                        Divider(color: Color.fromRGBO(40, 59, 74, 0.5), indent: 16.0, endIndent: 16.0),
                        Text(
                          'Budget Renewal',
                          style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<_BudgetAmountOption>(
                                value: _selectedBudgetAmount,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Budget Amount',
                                  hintText: 'Select budget amount',
                                  border: const OutlineInputBorder(),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: themeData.colorScheme.error),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: themeData.colorScheme.error),
                                  ),
                                ),
                                items: _presetBudgetAmountOptions
                                    .map(
                                      (_BudgetAmountOptionData option) =>
                                          DropdownMenuItem<_BudgetAmountOption>(
                                            value: option.type,
                                            child: Text(option.label),
                                          ),
                                    )
                                    .toList(),
                                onChanged: (_BudgetAmountOption? value) {
                                  setState(() {
                                    _selectedBudgetAmount = value;
                                    if (value != _BudgetAmountOption.custom) {
                                      _customBudgetAmount = null;
                                      _maxBudgetController.clear();
                                    }
                                  });
                                },
                                validator: (_) {
                                  if (!_showBudgetFields) {
                                    return null;
                                  }
                                  if (_selectedBudgetAmount == null) {
                                    return 'Select budget amount';
                                  }
                                  if (_selectedBudgetAmount == _BudgetAmountOption.custom) {
                                    final String trimmedValue = _maxBudgetController.text.trim();
                                    if (trimmedValue.isEmpty) {
                                      return 'Enter custom budget amount';
                                    }
                                    if (int.tryParse(trimmedValue) == null) {
                                      return 'Please enter a valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _toggleBudgetFields,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        if (_selectedBudgetAmount == _BudgetAmountOption.custom) ...<Widget>[
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _maxBudgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Custom Budget Amount',
                              hintText: 'Enter budget in sats',
                              border: const OutlineInputBorder(),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                            ),
                            validator: (String? value) {
                              if (_selectedBudgetAmount != _BudgetAmountOption.custom) {
                                return null;
                              }
                              final String trimmedValue = value?.trim() ?? '';
                              if (trimmedValue.isEmpty) {
                                return 'Enter custom budget amount';
                              }
                              if (int.tryParse(trimmedValue) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                            onChanged: (String value) {
                              final int? parsedValue = int.tryParse(value.trim());
                              setState(() {
                                _customBudgetAmount = parsedValue;
                              });
                            },
                          ),
                        ],
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
                                _customRenewalTimeMins = null;
                                _customRenewalTimeController.clear();
                              }
                            });
                          },
                          validator: (_) {
                            if (!_showBudgetFields) {
                              return null;
                            }
                            final int? renewalTimeMins = _selectedRenewalTimeMinutes;
                            if (renewalTimeMins != null) {
                              final int? expiryTimeMins = _selectedExpiryTimeMinutes;
                              if (expiryTimeMins != null && renewalTimeMins > expiryTimeMins) {
                                return 'Reset time cannot be greater than expiry time';
                              }
                            }

                            return null;
                          },
                        ),
                        if (_selectedBudgetRenewal == _BudgetRenewalType.custom) ...<Widget>[
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _customRenewalTimeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Custom Renewal Time',
                              hintText: 'Enter renewal time in minutes',
                              border: const OutlineInputBorder(),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeData.colorScheme.error),
                              ),
                            ),
                            validator: (String? value) {
                              if (_selectedBudgetRenewal != _BudgetRenewalType.custom) {
                                return null;
                              }
                              final String trimmedValue = value?.trim() ?? '';
                              if (trimmedValue.isEmpty) {
                                return 'Enter custom renewal time';
                              }
                              final int? parsedValue = int.tryParse(trimmedValue);
                              if (parsedValue == null) {
                                return 'Please enter a valid number';
                              }
                              if (parsedValue <= 0) {
                                return 'Renewal time must be greater than 0';
                              }
                              final int? expiryTimeMins = _selectedExpiryTimeMinutes;
                              if (expiryTimeMins != null && parsedValue > expiryTimeMins) {
                                return 'Renewal time cannot be greater than expiry time';
                              }
                              return null;
                            },
                            onChanged: (String value) {
                              final int? parsedValue = int.tryParse(value.trim());
                              setState(() {
                                _customRenewalTimeMins = parsedValue;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 16.0),
                      ],
                      if (_showExpiryFields) ...<Widget>[
                        Divider(color: Color.fromRGBO(40, 59, 74, 0.5), indent: 16.0, endIndent: 16.0),
                        Text(
                          'Connection Expiration',
                          style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<_ExpiryTimeOption>(
                                value: _selectedExpiryTime,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Expiration Time',
                                  hintText: 'Select expiration time',
                                  border: const OutlineInputBorder(),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: themeData.colorScheme.error),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: themeData.colorScheme.error),
                                  ),
                                ),
                                items: _presetExpiryTimeOptions
                                    .map(
                                      (_ExpiryTimeOptionData option) => DropdownMenuItem<_ExpiryTimeOption>(
                                        value: option.type,
                                        child: Text(option.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (_ExpiryTimeOption? value) {
                                  setState(() {
                                    _selectedExpiryTime = value;
                                    if (value == _ExpiryTimeOption.custom) {
                                      // Custom not implemented yet
                                    }
                                  });
                                },
                                validator: (_) {
                                  if (!_showExpiryFields) {
                                    return null;
                                  }
                                  if (_selectedExpiryTime == null) {
                                    return 'Select expiration time';
                                  }
                                  if (_selectedExpiryTime == _ExpiryTimeOption.custom) {
                                    return 'Custom expiration not implemented yet';
                                  }
                                  final int? renewalTimeMins = _selectedRenewalTimeMinutes;
                                  final int? expiryTimeMins = _selectedExpiryTimeMinutes;
                                  if (expiryTimeMins != null &&
                                      renewalTimeMins != null &&
                                      _showBudgetFields) {
                                    if (renewalTimeMins > expiryTimeMins) {
                                      return 'Expiry time must be greater than reset time';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _toggleExpiryFields,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: <Widget>[
                    if (!_showBudgetFields)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            ),
                            onPressed: _toggleBudgetFields,
                            child: const Text('SET BUDGET'),
                          ),
                        ),
                      ),
                    if (!_showBudgetFields && !_showExpiryFields) const SizedBox(height: 16),
                    if (!_showExpiryFields)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            ),
                            onPressed: _toggleExpiryFields,
                            child: const Text('SET EXPIRATION TIME'),
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
