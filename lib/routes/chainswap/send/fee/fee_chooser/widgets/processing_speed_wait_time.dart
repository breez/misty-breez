import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';

class ProcessingSpeedWaitTime extends StatelessWidget {
  final Duration waitingTime;

  const ProcessingSpeedWaitTime(
    this.waitingTime, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    final hours = waitingTime.inHours;

    String message = texts.fee_chooser_estimated_delivery_minutes(
      waitingTime.inMinutes.toString(),
    );
    if (hours >= 12.0) {
      message = texts.fee_chooser_estimated_delivery_more_than_day;
    } else if (hours >= 4) {
      message = texts.fee_chooser_estimated_delivery_hour_range(
        hours.ceil().toString(),
      );
    } else if (hours >= 2.0) {
      message = texts.fee_chooser_estimated_delivery_hours(
        hours.ceil().toString(),
      );
    } else if (hours >= 1.0) {
      message = texts.fee_chooser_estimated_delivery_hour;
    }

    return Text(
      message,
      style: themeData.textTheme.labelLarge!.copyWith(
        color: themeData.colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }
}
