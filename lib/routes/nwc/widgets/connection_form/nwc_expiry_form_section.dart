import 'package:flutter/material.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_form/nwc_expiry_date_picker_sheet.dart';
import 'package:misty_breez/utils/utils.dart';

class NwcExpiryFormSection extends StatefulWidget {
  final DateTime? expiryDate;
  final int? renewalTimeMins;
  final ValueChanged<DateTime?> onExpiryDateChanged;

  const NwcExpiryFormSection({
    required this.onExpiryDateChanged,
    this.expiryDate,
    this.renewalTimeMins,
    super.key,
  });

  @override
  State<NwcExpiryFormSection> createState() => _NwcExpiryFormSectionState();
}

class _NwcExpiryFormSectionState extends State<NwcExpiryFormSection> {
  late final TextEditingController _expiryDateController;

  @override
  void initState() {
    super.initState();
    _expiryDateController = TextEditingController(
      text: widget.expiryDate != null ? BreezDateUtils.formatYearMonthDay(widget.expiryDate!) : '',
    );
  }

  @override
  void didUpdateWidget(NwcExpiryFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expiryDate != oldWidget.expiryDate) {
      _expiryDateController.text = widget.expiryDate != null
          ? BreezDateUtils.formatYearMonthDay(widget.expiryDate!)
          : '';
    }
  }

  @override
  void dispose() {
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showNwcExpiryDatePickerSheet(context, initialDate: widget.expiryDate);
    if (picked != null) {
      widget.onExpiryDateChanged(picked);
    }
  }

  void _clearDate() {
    widget.onExpiryDateChanged(null);
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
          readOnly: true,
          onTap: _showDatePicker,
          decoration: InputDecoration(
            labelText: 'Expiration (Optional)',
            hintText: 'Select expiration date',
            border: const OutlineInputBorder(),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.error),
            ),
            suffixIcon: widget.expiryDate != null
                ? IconButton(icon: const Icon(Icons.close), onPressed: _clearDate, tooltip: 'Clear date')
                : const Icon(Icons.calendar_today),
          ),
          controller: _expiryDateController,
          validator: (_) {
            if (widget.expiryDate != null) {
              if (widget.expiryDate!.isBefore(DateTime.now())) {
                return 'Expiration date must be in the future';
              }
              if (widget.renewalTimeMins != null) {
                final DateTime now = DateTime.now();
                final int expiryMins = widget.expiryDate!.difference(now).inMinutes;
                if (widget.renewalTimeMins! > expiryMins) {
                  return 'Expiry time must be greater than renewal time';
                }
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
