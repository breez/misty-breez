import 'package:flutter/material.dart';
import 'package:misty_breez/routes/nwc/models/nwc_form_models.dart';

class NwcBudgetFormSection extends StatefulWidget {
  final bool showBudgetFields;
  final BudgetAmountOption? selectedBudgetAmount;
  final BudgetRenewalType? selectedBudgetRenewal;
  final int? customBudgetAmount;
  final int? customRenewalTimeMins;
  final int? expiryTimeMins;
  final ValueChanged<bool> onToggle;
  final Function(
    BudgetAmountOption? amountOption,
    int? customAmount,
    BudgetRenewalType? renewalOption,
    int? customRenewal,
  )
  onValuesChanged;

  const NwcBudgetFormSection({
    required this.showBudgetFields,
    required this.onToggle,
    required this.onValuesChanged,
    this.selectedBudgetAmount,
    this.selectedBudgetRenewal,
    this.customBudgetAmount,
    this.customRenewalTimeMins,
    this.expiryTimeMins,
    super.key,
  });

  @override
  State<NwcBudgetFormSection> createState() => _NwcBudgetFormSectionState();
}

class _NwcBudgetFormSectionState extends State<NwcBudgetFormSection> {
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _customRenewalTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customBudgetAmount != null) {
      _maxBudgetController.text = widget.customBudgetAmount.toString();
    }
    if (widget.customRenewalTimeMins != null) {
      _customRenewalTimeController.text = widget.customRenewalTimeMins.toString();
    }
  }

  @override
  void didUpdateWidget(NwcBudgetFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customBudgetAmount != oldWidget.customBudgetAmount) {
      if (widget.customBudgetAmount != null &&
          _maxBudgetController.text != widget.customBudgetAmount.toString()) {
        _maxBudgetController.text = widget.customBudgetAmount.toString();
      } else if (widget.customBudgetAmount == null) {
        _maxBudgetController.clear();
      }
    }
    if (widget.customRenewalTimeMins != oldWidget.customRenewalTimeMins) {
      if (widget.customRenewalTimeMins != null &&
          _customRenewalTimeController.text != widget.customRenewalTimeMins.toString()) {
        _customRenewalTimeController.text = widget.customRenewalTimeMins.toString();
      } else if (widget.customRenewalTimeMins == null) {
        _customRenewalTimeController.clear();
      }
    }
  }

  @override
  void dispose() {
    _maxBudgetController.dispose();
    _customRenewalTimeController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<BudgetRenewalType>> _buildBudgetRenewalItems() {
    final List<DropdownMenuItem<BudgetRenewalType>> items = presetBudgetRenewalOptions
        .map(
          (BudgetRenewalOption option) =>
              DropdownMenuItem<BudgetRenewalType>(value: option.type, child: Text(option.label)),
        )
        .toList();

    if (widget.customRenewalTimeMins != null &&
        !presetBudgetRenewalOptions.any(
          (BudgetRenewalOption option) => option.minutes == widget.customRenewalTimeMins,
        )) {
      items.add(
        const DropdownMenuItem<BudgetRenewalType>(
          value: BudgetRenewalType.custom,
          child: Text('CUSTOM (\${widget.customRenewalTimeMins}m)'),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (!widget.showBudgetFields) {
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
            child: const Text('SET BUDGET'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Divider(color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
        Text('Budget Renewal', style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<BudgetAmountOption>(
                key: ValueKey<BudgetAmountOption?>(widget.selectedBudgetAmount),
                initialValue: widget.selectedBudgetAmount,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  hintText: 'Select budget amount',
                  border: const OutlineInputBorder(),
                  errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeData.colorScheme.error),
                  ),
                ),
                items: presetBudgetAmountOptions
                    .map(
                      (BudgetAmountOptionData option) =>
                          DropdownMenuItem<BudgetAmountOption>(value: option.type, child: Text(option.label)),
                    )
                    .toList(),
                onChanged: (BudgetAmountOption? value) {
                  widget.onValuesChanged(
                    value,
                    value == BudgetAmountOption.custom ? widget.customBudgetAmount : null,
                    widget.selectedBudgetRenewal,
                    widget.customRenewalTimeMins,
                  );
                },
                validator: (_) {
                  if (widget.selectedBudgetAmount == null) {
                    return 'Select budget amount';
                  }
                  if (widget.selectedBudgetAmount == BudgetAmountOption.custom) {
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
              onPressed: () => widget.onToggle(false),
              tooltip: 'Close',
            ),
          ],
        ),
        if (widget.selectedBudgetAmount == BudgetAmountOption.custom) ...<Widget>[
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _maxBudgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Custom Budget Amount',
              hintText: 'Enter budget in sats',
              border: const OutlineInputBorder(),
              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: themeData.colorScheme.error),
              ),
            ),
            validator: (String? value) {
              if (widget.selectedBudgetAmount != BudgetAmountOption.custom) {
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
              widget.onValuesChanged(
                widget.selectedBudgetAmount,
                parsedValue,
                widget.selectedBudgetRenewal,
                widget.customRenewalTimeMins,
              );
            },
          ),
        ],
        const SizedBox(height: 16.0),
        DropdownButtonFormField<BudgetRenewalType>(
          key: ValueKey<BudgetRenewalType?>(widget.selectedBudgetRenewal),
          initialValue: widget.selectedBudgetRenewal,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Reset Interval',
            hintText: 'Choose how often the budget renews',
            border: const OutlineInputBorder(),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeData.colorScheme.error),
            ),
          ),
          items: _buildBudgetRenewalItems(),
          onChanged: (BudgetRenewalType? value) {
            widget.onValuesChanged(
              widget.selectedBudgetAmount,
              widget.customBudgetAmount,
              value,
              value == BudgetRenewalType.custom ? widget.customRenewalTimeMins : null,
            );
          },
          validator: (_) {
            int? renewalTimeMins;
            if (widget.selectedBudgetRenewal == BudgetRenewalType.custom) {
              renewalTimeMins = widget.customRenewalTimeMins;
            } else {
              for (final BudgetRenewalOption option in presetBudgetRenewalOptions) {
                if (option.type == widget.selectedBudgetRenewal) {
                  renewalTimeMins = option.minutes;
                  break;
                }
              }
            }

            if (renewalTimeMins != null) {
              final int? expiryTimeMins = widget.expiryTimeMins;
              if (expiryTimeMins != null && renewalTimeMins > expiryTimeMins) {
                return 'Reset time cannot be greater than expiry time';
              }
            }

            return null;
          },
        ),
        if (widget.selectedBudgetRenewal == BudgetRenewalType.custom) ...<Widget>[
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _customRenewalTimeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Custom Renewal Time',
              hintText: 'Enter renewal time in minutes',
              border: const OutlineInputBorder(),
              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: themeData.colorScheme.error)),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: themeData.colorScheme.error),
              ),
            ),
            validator: (String? value) {
              if (widget.selectedBudgetRenewal != BudgetRenewalType.custom) {
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
              final int? expiryTimeMins = widget.expiryTimeMins;
              if (expiryTimeMins != null && parsedValue > expiryTimeMins) {
                return 'Renewal time cannot be greater than expiry time';
              }
              return null;
            },
            onChanged: (String value) {
              final int? parsedValue = int.tryParse(value.trim());
              widget.onValuesChanged(
                widget.selectedBudgetAmount,
                widget.customBudgetAmount,
                widget.selectedBudgetRenewal,
                parsedValue,
              );
            },
          ),
        ],
        const SizedBox(height: 16.0),
      ],
    );
  }
}
