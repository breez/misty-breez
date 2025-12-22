import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/widgets/amount_form_field/input_formatter/sat_amount_form_field_formatter.dart';

final Logger _logger = Logger('NwcBudgetFormSection');

class NwcBudgetFormSection extends StatefulWidget {
  final int? budgetAmount;

  final int? renewalIntervalDays;
  final int? expirationTimeMins;

  final Function(int? budgetAmount, int? renewalDays) onValuesChanged;

  const NwcBudgetFormSection({
    required this.onValuesChanged,
    this.budgetAmount,
    this.renewalIntervalDays,
    this.expirationTimeMins,
    super.key,
  });

  @override
  State<NwcBudgetFormSection> createState() => _NwcBudgetFormSectionState();
}

class _NwcBudgetFormSectionState extends State<NwcBudgetFormSection> {
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _renewalDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.budgetAmount != null) {
      _maxBudgetController.text = BitcoinCurrency.sat.format(widget.budgetAmount!, includeDisplayName: false);
    }
    if (widget.renewalIntervalDays != null) {
      _renewalDaysController.text = widget.renewalIntervalDays.toString();
    }
  }

  @override
  void didUpdateWidget(NwcBudgetFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.budgetAmount != oldWidget.budgetAmount) {
      if (widget.budgetAmount != null) {
        final String formatted = BitcoinCurrency.sat.format(widget.budgetAmount!, includeDisplayName: false);
        if (_maxBudgetController.text != formatted) {
          _maxBudgetController.text = formatted;
        }
      } else if (widget.budgetAmount == null) {
        _maxBudgetController.clear();
      }
    }
    if (widget.renewalIntervalDays != oldWidget.renewalIntervalDays) {
      if (widget.renewalIntervalDays != null &&
          _renewalDaysController.text != widget.renewalIntervalDays.toString()) {
        _renewalDaysController.text = widget.renewalIntervalDays.toString();
      } else if (widget.renewalIntervalDays == null) {
        _renewalDaysController.clear();
      }
    }
  }

  @override
  void dispose() {
    _maxBudgetController.dispose();
    _renewalDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Divider(height: 8.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _maxBudgetController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[SatAmountFormFieldFormatter()],
          decoration: InputDecoration(
            labelText: 'Budget in sats (Optional)',
            border: const OutlineInputBorder(),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.error),
            ),
          ),
          validator: (String? value) {
            final String trimmedValue = value?.trim() ?? '';

            final String renewalText = _renewalDaysController.text.trim();
            final bool hasRenewalTime =
                widget.renewalIntervalDays != null ||
                (renewalText.isNotEmpty && int.tryParse(renewalText) != null);

            if (hasRenewalTime && trimmedValue.isEmpty) {
              return 'Budget is required when renewal interval is set';
            }

            if (trimmedValue.isEmpty) {
              // Empty means no budget / unlimited, which is allowed.
              return null;
            }
            try {
              final int parsedValue = BitcoinCurrency.sat.parse(trimmedValue);
              if (parsedValue <= 0) {
                return 'Please enter a valid number';
              }
            } catch (e) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (String value) {
            final String trimmedValue = value.trim();
            if (trimmedValue.isEmpty) {
              widget.onValuesChanged(null, widget.renewalIntervalDays);
              return;
            }
            try {
              final int parsedValue = BitcoinCurrency.sat.parse(trimmedValue);
              widget.onValuesChanged(parsedValue, widget.renewalIntervalDays);
            } catch (e) {
              _logger.warning(e);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'This is the maximum your connection can spend.',
            style: themeData.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 16.0),
        const Divider(height: 8.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _renewalDaysController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Renewal Interval (Optional)',
            border: const OutlineInputBorder(),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.error),
            ),
          ),
          validator: (String? value) {
            final String trimmedValue = value?.trim() ?? '';

            if (trimmedValue.isNotEmpty) {
              final int? parsedValue = int.tryParse(trimmedValue);
              if (parsedValue == null) {
                return 'Please enter a valid number';
              }
              if (parsedValue < 1 || parsedValue > 365) {
                return 'Renewal interval must be between 1 and 365 days';
              }
              final int? expirationTimeMins = widget.expirationTimeMins;
              if (expirationTimeMins != null) {
                final int renewalIntervalMins = parsedValue * 1440;
                if (renewalIntervalMins > expirationTimeMins) {
                  return 'Renewal interval cannot be greater than expiration';
                }
              }
            }
            return null;
          },
          onChanged: (String value) {
            final String trimmedValue = value.trim();
            final int? parsedValue = trimmedValue.isEmpty ? null : int.tryParse(trimmedValue);
            widget.onValuesChanged(widget.budgetAmount, parsedValue);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Your budget renews after the set number of days.',
            style: themeData.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
