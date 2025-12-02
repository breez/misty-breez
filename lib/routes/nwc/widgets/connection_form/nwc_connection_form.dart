import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';

import 'package:misty_breez/routes/nwc/models/nwc_form_models.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_form/nwc_budget_form_section.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_form/nwc_expiry_form_section.dart';

class NwcConnectionForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final bool isEditMode;
  final NwcConnectionModel? existingConnection;
  final Function(
    int? maxBudgetSat,
    int? renewalTimeMins,
    int? expiryTimeMins,
    bool showBudgetFields,
    bool showExpiryFields,
  )
  onValuesChanged;

  const NwcConnectionForm({
    required this.formKey,
    required this.nameController,
    required this.isEditMode,
    required this.onValuesChanged,
    this.existingConnection,
    super.key,
  });

  @override
  State<NwcConnectionForm> createState() => _NwcConnectionFormState();
}

class _NwcConnectionFormState extends State<NwcConnectionForm> {
  bool _showBudgetFields = false;
  bool _showExpiryFields = false;
  BudgetRenewalType? _selectedBudgetRenewal = BudgetRenewalType.daily;
  int? _customRenewalTimeMins;
  BudgetAmountOption? _selectedBudgetAmount;
  ExpiryTimeOption? _selectedExpiryTime;
  int? _customBudgetAmount;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.existingConnection != null) {
      final NwcConnectionModel connection = widget.existingConnection!;
      if (connection.periodicBudget != null) {
        final int maxBudgetSat = connection.periodicBudget!.maxBudgetSat.toInt();
        _selectedBudgetAmount = _resolveBudgetAmountOption(maxBudgetSat);
        if (_selectedBudgetAmount == BudgetAmountOption.custom) {
          _customBudgetAmount = maxBudgetSat;
        }
        if (connection.periodicBudget!.renewsAt != null) {
          final int renewalIntervalMins =
              ((connection.periodicBudget!.renewsAt! - connection.periodicBudget!.updatedAt) / 60).round();
          _selectedBudgetRenewal = _resolveBudgetRenewalType(renewalIntervalMins);
        } else {
          _selectedBudgetRenewal = BudgetRenewalType.never;
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
          _selectedExpiryTime = ExpiryTimeOption.never;
          _showExpiryFields = true;
        }
      } else {
        _selectedExpiryTime = ExpiryTimeOption.never;
        _showExpiryFields = false;
      }
    }
    _notifyValuesChanged();
  }

  void _notifyValuesChanged() {
    widget.onValuesChanged(
      _selectedBudgetAmountSats,
      _selectedRenewalTimeMinutes,
      _selectedExpiryTimeMinutes,
      _showBudgetFields,
      _showExpiryFields,
    );
  }

  void _toggleBudgetFields(bool value) {
    setState(() {
      _showBudgetFields = value;
      if (!_showBudgetFields) {
        _selectedBudgetRenewal = BudgetRenewalType.daily;
        _customRenewalTimeMins = null;
        _selectedBudgetAmount = null;
        _customBudgetAmount = null;
      } else {
        if (widget.existingConnection?.periodicBudget == null) {
          _selectedBudgetAmount = BudgetAmountOption.unlimited;
          _selectedBudgetRenewal = BudgetRenewalType.never;
        } else {
          _selectedBudgetRenewal ??= BudgetRenewalType.daily;
        }
      }
      _notifyValuesChanged();
    });
  }

  void _toggleExpiryFields(bool value) {
    setState(() {
      _showExpiryFields = value;
      if (!_showExpiryFields) {
        _selectedExpiryTime = null;
      } else {
        if (widget.existingConnection?.expiresAt == null) {
          _selectedExpiryTime = ExpiryTimeOption.never;
        }
      }
      _notifyValuesChanged();
    });
  }

  int? get _selectedRenewalTimeMinutes {
    if (!_showBudgetFields || _selectedBudgetRenewal == null) {
      return null;
    }
    if (_selectedBudgetRenewal == BudgetRenewalType.custom) {
      return _customRenewalTimeMins;
    }
    for (final BudgetRenewalOption option in presetBudgetRenewalOptions) {
      if (option.type == _selectedBudgetRenewal) {
        return option.minutes;
      }
    }
    return null;
  }

  BudgetRenewalType _resolveBudgetRenewalType(int renewalTimeMins) {
    const int toleranceMins = 15;
    for (final BudgetRenewalOption option in presetBudgetRenewalOptions) {
      if ((option.minutes - renewalTimeMins).abs() <= toleranceMins) {
        _customRenewalTimeMins = null;
        return option.type;
      }
    }
    _customRenewalTimeMins = renewalTimeMins;
    return BudgetRenewalType.custom;
  }

  BudgetAmountOption _resolveBudgetAmountOption(int sats) {
    for (final BudgetAmountOptionData option in presetBudgetAmountOptions) {
      if (option.sats == sats) {
        _customBudgetAmount = null;
        return option.type;
      }
    }
    _customBudgetAmount = sats;
    return BudgetAmountOption.custom;
  }

  ExpiryTimeOption _resolveExpiryTimeOption(int minutes) {
    for (final ExpiryTimeOptionData option in presetExpiryTimeOptions) {
      if (option.minutes == minutes) {
        return option.type;
      }
    }
    if (minutes <= 0) {
      return ExpiryTimeOption.never;
    }
    return ExpiryTimeOption.custom;
  }

  int? get _selectedBudgetAmountSats {
    if (!_showBudgetFields || _selectedBudgetAmount == null) {
      return null;
    }
    if (_selectedBudgetAmount == BudgetAmountOption.unlimited) {
      return null; // Unlimited
    }
    if (_selectedBudgetAmount == BudgetAmountOption.custom) {
      return _customBudgetAmount;
    }
    for (final BudgetAmountOptionData option in presetBudgetAmountOptions) {
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
    if (_selectedExpiryTime == ExpiryTimeOption.never) {
      return null;
    }
    if (_selectedExpiryTime == ExpiryTimeOption.custom) {
      // TODO(ayush): Custom not implemented yet
      return null;
    }
    for (final ExpiryTimeOptionData option in presetExpiryTimeOptions) {
      if (option.type == _selectedExpiryTime) {
        return option.minutes;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: widget.nameController,
            autofocus: !widget.isEditMode,
            enabled: !widget.isEditMode,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Name of the app or purpose of the connection',
              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: themeData.colorScheme.error),
              ),
              border: const OutlineInputBorder(),
              disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          NwcBudgetFormSection(
            showBudgetFields: _showBudgetFields,
            selectedBudgetAmount: _selectedBudgetAmount,
            selectedBudgetRenewal: _selectedBudgetRenewal,
            customBudgetAmount: _customBudgetAmount,
            customRenewalTimeMins: _customRenewalTimeMins,
            expiryTimeMins: _selectedExpiryTimeMinutes,
            onToggle: _toggleBudgetFields,
            onValuesChanged:
                (
                  BudgetAmountOption? amountOption,
                  int? customAmount,
                  BudgetRenewalType? renewalOption,
                  int? customRenewal,
                ) {
                  setState(() {
                    _selectedBudgetAmount = amountOption;
                    _customBudgetAmount = customAmount;
                    _selectedBudgetRenewal = renewalOption;
                    _customRenewalTimeMins = customRenewal;
                    _notifyValuesChanged();
                  });
                },
          ),
          NwcExpiryFormSection(
            showExpiryFields: _showExpiryFields,
            showBudgetFields: _showBudgetFields,
            selectedExpiryTime: _selectedExpiryTime,
            renewalTimeMins: _selectedRenewalTimeMinutes,
            onToggle: _toggleExpiryFields,
            onValuesChanged: (ExpiryTimeOption? value) {
              setState(() {
                _selectedExpiryTime = value;
                _notifyValuesChanged();
              });
            },
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
                  onPressed: () => _toggleExpiryFields(true),
                  child: const Text('SET EXPIRATION TIME'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
