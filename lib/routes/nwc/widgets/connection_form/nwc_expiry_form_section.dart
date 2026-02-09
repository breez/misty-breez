import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_form/nwc_expiry_date_picker_sheet.dart';
import 'package:misty_breez/utils/utils.dart';

class NwcExpiryFormSection extends StatefulWidget {
  final DateTime? expirationDate;
  final int? renewalIntervalMins;
  final ValueChanged<DateTime?> onExpirationDateChanged;

  const NwcExpiryFormSection({
    required this.onExpirationDateChanged,
    this.expirationDate,
    this.renewalIntervalMins,
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
      text: widget.expirationDate != null ? BreezDateUtils.formatYearMonthDay(widget.expirationDate!) : '',
    );
  }

  @override
  void didUpdateWidget(NwcExpiryFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expirationDate != oldWidget.expirationDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _expiryDateController.text = widget.expirationDate != null
              ? BreezDateUtils.formatYearMonthDay(widget.expirationDate!)
              : '';
        }
      });
    }
  }

  @override
  void dispose() {
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showNwcExpirationDatePickerSheet(
      context,
      initialDate: widget.expirationDate,
    );
    if (picked != null) {
      widget.onExpirationDateChanged(picked);
    }
  }

  void _clearDate() {
    widget.onExpirationDateChanged(null);
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
            suffixIcon: widget.expirationDate != null
                ? IconButton(icon: const Icon(Icons.close), onPressed: _clearDate, tooltip: 'Clear date')
                : IconButton(icon: SvgPicture.asset('assets/icons/calendar.svg'), onPressed: _showDatePicker),
          ),
          controller: _expiryDateController,
          validator: (_) {
            if (widget.expirationDate != null) {
              if (widget.expirationDate!.isBefore(DateTime.now())) {
                return 'Expiration date must be in the future';
              }
              if (widget.renewalIntervalMins != null) {
                final DateTime now = DateTime.now();
                final int expirationTimeMins = widget.expirationDate!.difference(now).inMinutes;
                if (widget.renewalIntervalMins! > expirationTimeMins) {
                  return 'Expiration must be greater than renewal interval';
                }
              }
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'This connection expires after the set time.',
            style: themeData.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
