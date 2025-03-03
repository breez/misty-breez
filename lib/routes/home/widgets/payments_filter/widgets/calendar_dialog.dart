import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/date/breez_date_utils.dart';

class CalendarDialog extends StatefulWidget {
  final DateTime firstDate;

  const CalendarDialog(this.firstDate, {super.key});

  @override
  CalendarDialogState createState() => CalendarDialogState();
}

class CalendarDialogState extends State<CalendarDialog> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime _endDate = DateTime.now();
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startDate = widget.firstDate;
    _startDateController.text = BreezDateUtils.formatYearMonthDay(_startDate);
    _endDateController.text = BreezDateUtils.formatYearMonthDay(_endDate);
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return AlertDialog(
      title: Text(
        texts.pos_transactions_range_dialog_title,
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: _selectDateButton(
              texts.pos_transactions_range_dialog_start,
              _startDateController,
              true,
            ),
          ),
          Flexible(
            child: _selectDateButton(
              texts.pos_transactions_range_dialog_end,
              _endDateController,
              false,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _clearFilter,
          child: Text(
            texts.pos_transactions_range_dialog_clear,
            style: cancelButtonStyle.copyWith(
              color: themeData.isLightTheme ? Colors.red : themeData.colorScheme.error,
            ),
          ),
        ),
        TextButton(
          child: Text(
            texts.pos_transactions_range_dialog_apply,
            style: themeData.primaryTextTheme.labelLarge,
          ),
          onPressed: () => _applyFilter(context),
        ),
      ],
    );
  }

  void _applyFilter(BuildContext context) {
    // Check if filter is unchanged
    final NavigatorState navigator = Navigator.of(context);
    if (_startDate != widget.firstDate || _endDate.day != DateTime.now().day) {
      navigator.pop(
        <DateTime>[
          DateTime(_startDate.year, _startDate.month, _startDate.day),
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59, 999),
        ],
      );
    } else {
      navigator.pop();
    }
  }

  Widget _selectDateButton(
    String label,
    TextEditingController textEditingController,
    bool isStartBtn,
  ) {
    final ThemeData themeData = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectDate(context, isStartBtn);
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Theme(
        data: themeData.isLightTheme
            ? themeData
            : themeData.copyWith(
                disabledColor: themeData.customData.paymentListBgColorLight,
              ),
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: themeData.dialogTheme.contentTextStyle,
          ),
          controller: textEditingController,
          enabled: false,
          style: themeData.dialogTheme.contentTextStyle,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartBtn) async {
    // TODO(erdemyerebasmaz): Show error if end date is earlier than start date or do not allow picking an earlier date at all
    final DateTime? selectedDate = await showDatePicker(
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      context: context,
      initialDate: isStartBtn ? _startDate : _endDate,
      firstDate: widget.firstDate,
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        final ThemeData themeData = Theme.of(context);
        return Theme(
          data: themeData.isLightTheme
              ? themeData.copyWith(colorScheme: themeData.colorScheme.copyWith(onSurface: Colors.black))
              : themeData,
          child: DatePickerTheme(data: Theme.of(context).calendarTheme, child: child!),
        );
      },
    );
    final Duration difference =
        isStartBtn ? selectedDate!.difference(_endDate) : selectedDate!.difference(_startDate);
    if (difference.inDays < 0) {
      setState(() {
        isStartBtn ? _startDate = selectedDate : _endDate = selectedDate;
        _startDateController.text = BreezDateUtils.formatYearMonthDay(_startDate);
        _endDateController.text = BreezDateUtils.formatYearMonthDay(_endDate);
      });
    } else {
      setState(() {
        if (isStartBtn) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
        _startDateController.text = BreezDateUtils.formatYearMonthDay(_startDate);
        _endDateController.text = BreezDateUtils.formatYearMonthDay(_endDate);
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = widget.firstDate;
      _endDate = DateTime.now();
      _startDateController.text = '';
      _endDateController.text = '';
    });
  }
}
