import 'package:flutter/material.dart';
import 'package:misty_breez/routes/nwc/models/nwc_form_models.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_form/nwc_expiry_date_picker_sheet.dart';
import 'package:misty_breez/utils/utils.dart';

class NwcExpiryFormSection extends StatefulWidget {
  final bool showExpiryFields;
  final bool showBudgetFields;
  final ExpiryTimeOption? selectedExpiryTime;
  final int? renewalTimeMins;
  final DateTime? customExpiryDate;
  final ValueChanged<bool> onToggle;
  final ValueChanged<ExpiryTimeOption?> onValuesChanged;
  final ValueChanged<DateTime?>? onCustomExpiryDateChanged;

  const NwcExpiryFormSection({
    required this.showExpiryFields,
    required this.showBudgetFields,
    required this.onToggle,
    required this.onValuesChanged,
    this.selectedExpiryTime,
    this.renewalTimeMins,
    this.customExpiryDate,
    this.onCustomExpiryDateChanged,
    super.key,
  });

  @override
  State<NwcExpiryFormSection> createState() => _NwcExpiryFormSectionState();
}

class _NwcExpiryFormSectionState extends State<NwcExpiryFormSection> {
  final TextEditingController _expiryTimeController = TextEditingController();

  @override
  void dispose() {
    _expiryTimeController.dispose();
    super.dispose();
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showNwcExpiryDatePickerSheet(
      context,
      initialDate: widget.customExpiryDate,
    );
    if (picked != null && widget.onCustomExpiryDateChanged != null) {
      widget.onCustomExpiryDateChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (!widget.showExpiryFields) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48.0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
            onPressed: () => widget.onToggle(true),
            child: const Text('SET EXPIRATION TIME'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Divider(color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
        Text(
          'Connection Expiration',
          style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<ExpiryTimeOption>(
                initialValue: widget.selectedExpiryTime,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Expiration Time',
                  hintText: 'Select expiration time',
                  border: const OutlineInputBorder(),
                  errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeData.colorScheme.error),
                  ),
                ),
                items: presetExpiryTimeOptions
                    .map(
                      (ExpiryTimeOptionData option) =>
                          DropdownMenuItem<ExpiryTimeOption>(value: option.type, child: Text(option.label)),
                    )
                    .toList(),
                onChanged: widget.onValuesChanged,
                validator: (_) {
                  if (widget.selectedExpiryTime == null) {
                    return 'Select expiration time';
                  }
                  if (widget.selectedExpiryTime == ExpiryTimeOption.custom) {
                    if (widget.customExpiryDate == null) {
                      return 'Please select a custom expiration date';
                    }
                    if (widget.customExpiryDate!.isBefore(DateTime.now())) {
                      return 'Expiration date must be in the future';
                    }
                    if (widget.renewalTimeMins != null && widget.showBudgetFields) {
                      final DateTime now = DateTime.now();
                      final int customExpiryMins = widget.customExpiryDate!.difference(now).inMinutes;
                      if (widget.renewalTimeMins! > customExpiryMins) {
                        return 'Expiry time must be greater than reset time';
                      }
                    }
                  } else {
                    final int? renewalTimeMins = widget.renewalTimeMins;
                    if (renewalTimeMins != null && widget.showBudgetFields) {
                      int? expiryTimeMins;
                      for (final ExpiryTimeOptionData option in presetExpiryTimeOptions) {
                        if (option.type == widget.selectedExpiryTime) {
                          expiryTimeMins = option.minutes;
                          break;
                        }
                      }

                      if (expiryTimeMins != null && renewalTimeMins > expiryTimeMins) {
                        return 'Expiry time must be greater than reset time';
                      }
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => widget.onToggle(false),
              tooltip: 'Close',
            ),
          ],
        ),
        if (widget.selectedExpiryTime == ExpiryTimeOption.custom) ...<Widget>[
          const SizedBox(height: 16.0),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
            icon: const Icon(Icons.calendar_today, size: 20.0),
            label: Text(
              widget.customExpiryDate != null
                  ? BreezDateUtils.formatYearMonthDayHourMinuteSecond(widget.customExpiryDate!)
                  : 'Select Date & Time',
            ),
            onPressed: _showDatePicker,
          ),
        ],
        const SizedBox(height: 16.0),
      ],
    );
  }
}
