import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_form/nwc_budget_form_section.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_form/nwc_expiry_form_section.dart';

class NwcConnectionForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final bool isEditMode;
  final NwcConnectionModel? existingConnection;
  final Function(int? maxBudgetSat, int? renewalIntervalMins, int? expirationTimeMins) onValuesChanged;

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
  int? _renewalIntervalDays;
  int? _customBudgetAmount;
  DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.existingConnection != null) {
      final NwcConnectionModel connection = widget.existingConnection!;
      if (connection.periodicBudget != null) {
        final int maxBudgetSat = connection.periodicBudget!.maxBudgetSat.toInt();
        _customBudgetAmount = maxBudgetSat;
        if (connection.periodicBudget!.renewsAt != null) {
          final int renewalIntervalMins =
              ((connection.periodicBudget!.renewsAt! - connection.periodicBudget!.updatedAt) / 60).round();
          _renewalIntervalDays = (renewalIntervalMins / 1440).round();
        }
      }
      if (connection.expiresAt != null) {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final int remainingMins = ((connection.expiresAt! - now) / 60).round();
        if (remainingMins > 0) {
          _expirationDate = DateTime.fromMillisecondsSinceEpoch(connection.expiresAt! * 1000);
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyValuesChanged();
    });
  }

  void _notifyValuesChanged() {
    widget.onValuesChanged(
      _selectedBudgetAmountSats,
      _renewalIntervalDays != null ? _renewalIntervalDays! * 1440 : null,
      _expirationDate?.difference(DateTime.now()).inMinutes,
    );
  }

  int? get _selectedRenewalIntervalMinutes {
    return _renewalIntervalDays != null ? _renewalIntervalDays! * 1440 : null;
  }

  int? get _selectedExpiryTimeMinutes {
    if (_expirationDate == null) {
      return null;
    }
    final DateTime now = DateTime.now();
    final int minutes = _expirationDate!.difference(now).inMinutes;
    return minutes > 0 ? minutes : null;
  }

  int? get _selectedBudgetAmountSats {
    return _customBudgetAmount;
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
            maxLength: 90,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: InputDecoration(
              labelText: 'Name',
              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: themeData.colorScheme.error),
              ),
              border: const OutlineInputBorder(),
              disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Name of the app or purpose of the connection.',
                    style: themeData.textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ),
                Text('${widget.nameController.text.length}/90', style: themeData.primaryTextTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          NwcBudgetFormSection(
            budgetAmount: _customBudgetAmount,
            renewalIntervalDays: _renewalIntervalDays,
            expirationTimeMins: _selectedExpiryTimeMinutes,
            onValuesChanged: (int? budgetAmount, int? renewalDays) {
              setState(() {
                _customBudgetAmount = budgetAmount;
                _renewalIntervalDays = renewalDays;
                _notifyValuesChanged();
              });
            },
          ),
          NwcExpiryFormSection(
            expirationDate: _expirationDate,
            renewalIntervalMins: _selectedRenewalIntervalMinutes,
            onExpirationDateChanged: (DateTime? date) {
              setState(() {
                _expirationDate = date;
                _notifyValuesChanged();
              });
            },
          ),
        ],
      ),
    );
  }
}
