import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/bottom_sheet_widgets.dart';

Future<DateTime?> showNwcExpiryDatePickerSheet(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
}) async {
  final ThemeData themeData = Theme.of(context);
  DateTime selectedDate = initialDate ?? DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = initialDate != null ? TimeOfDay.fromDateTime(initialDate) : TimeOfDay.now();

  if (selectedDate.isBefore(DateTime.now())) {
    selectedDate = DateTime.now().add(const Duration(days: 1));
    selectedTime = TimeOfDay.now();
  }

  final DateTime minDate = firstDate ?? DateTime.now();

  return await showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: themeData.customData.surfaceBgColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16.0,
              right: 16.0,
              top: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const BottomSheetHandle(),
                const BottomSheetTitle(title: 'Select Expiration Date & Time'),
                const SizedBox(height: 16.0),
                // Date picker
                Container(
                  decoration: BoxDecoration(
                    color: themeData.canvasColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Theme(
                    data: themeData.copyWith(datePickerTheme: themeData.calendarTheme),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: minDate,
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      onDateChanged: (DateTime date) {
                        setState(() {
                          selectedDate = date;
                          if (date.year == DateTime.now().year &&
                              date.month == DateTime.now().month &&
                              date.day == DateTime.now().day) {
                            final TimeOfDay now = TimeOfDay.now();
                            if (selectedTime.hour < now.hour ||
                                (selectedTime.hour == now.hour && selectedTime.minute <= now.minute)) {
                              selectedTime = TimeOfDay(hour: now.hour, minute: now.minute + 1);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Container(
                  decoration: BoxDecoration(
                    color: themeData.canvasColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Time:',
                        style: themeData.primaryTextTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(width: 16.0),
                      TextButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: BreezColors.blue[500]!,
                                    onPrimary: Colors.white,
                                    surface: themeData.customData.surfaceBgColor,
                                    onSurface: Colors.white,
                                  ),
                                  dialogBackgroundColor: themeData.customData.surfaceBgColor,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              final DateTime now = DateTime.now();
                              if (selectedDate.year == now.year &&
                                  selectedDate.month == now.month &&
                                  selectedDate.day == now.day) {
                                if (picked.hour < now.hour ||
                                    (picked.hour == now.hour && picked.minute <= now.minute)) {
                                  selectedTime = TimeOfDay(hour: now.hour, minute: now.minute + 1);
                                } else {
                                  selectedTime = picked;
                                }
                              } else {
                                selectedTime = picked;
                              }
                            });
                          }
                        },
                        child: Text(
                          selectedTime.format(context),
                          style: themeData.primaryTextTheme.bodyMedium?.copyWith(
                            color: BreezColors.blue[500],
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: BreezColors.blue[500],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                        onPressed: () {
                          final DateTime result = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          if (result.isAfter(DateTime.now())) {
                            Navigator.of(context).pop(result);
                          }
                        },
                        child: const Text('CONFIRM'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          );
        },
      );
    },
  );
}
