import 'package:flutter/material.dart';
import 'package:misty_breez/routes/nwc/models/nwc_form_models.dart';

class NwcExpiryFormSection extends StatefulWidget {
  final bool showExpiryFields;
  final bool showBudgetFields;
  final ExpiryTimeOption? selectedExpiryTime;
  final int? renewalTimeMins;
  final ValueChanged<bool> onToggle;
  final ValueChanged<ExpiryTimeOption?> onValuesChanged;

  const NwcExpiryFormSection({
    required this.showExpiryFields,
    required this.showBudgetFields,
    required this.onToggle,
    required this.onValuesChanged,
    this.selectedExpiryTime,
    this.renewalTimeMins,
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
        const Divider(color: Color.fromRGBO(40, 59, 74, 0.5), indent: 16.0, endIndent: 16.0),
        Text(
          'Connection Expiration',
          style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<ExpiryTimeOption>(
                value: widget.selectedExpiryTime,
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
                    return 'Custom expiration not implemented yet';
                  }
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
        const SizedBox(height: 16.0),
      ],
    );
  }
}
