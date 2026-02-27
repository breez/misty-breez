import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';

Future<DateTime?> showNwcExpirationDatePickerSheet(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
}) async {
  final ThemeData themeData = Theme.of(context);
  final DateTime minDate = firstDate ?? DateTime.now();
  final DateTime selectedDate = initialDate ?? DateTime.now().add(const Duration(days: 1));

  return await showDatePicker(
    context: context,
    initialDate: selectedDate.isBefore(minDate) ? minDate : selectedDate,
    firstDate: minDate,
    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: themeData.copyWith(
          datePickerTheme: themeData.calendarTheme,
          colorScheme: themeData.isLightTheme
              ? themeData.colorScheme.copyWith(onSurface: Colors.black)
              : themeData.colorScheme,
        ),
        child: child!,
      );
    },
  );
}
