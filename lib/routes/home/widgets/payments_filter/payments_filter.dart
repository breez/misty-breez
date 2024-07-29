import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/payments/payments_cubit.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/payment_filter_exporter.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/payments_filter_calendar.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/payments_filter_dropdown.dart';

class PaymentsFilters extends StatefulWidget {
  const PaymentsFilters({super.key});

  @override
  State<StatefulWidget> createState() => PaymentsFilterState();
}

class PaymentsFilterState extends State<PaymentsFilters> {
  String? _filter;
  Map<String, List<PaymentType>> _filterMap = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filter = null;
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (context, paymentsState) {
        if (_filter == null) {
          _filterMap = {
            texts.payments_filter_option_all: PaymentType.values,
            texts.payments_filter_option_sent: [PaymentType.send],
            texts.payments_filter_option_received: [PaymentType.receive],
          };
          _filter = _getFilterTypeString(
            context,
            paymentsState.paymentFilters.filters,
          );
        }

        return Row(
          children: [
            PaymentFilterExporter(_getFilterType()),
            PaymentsFilterCalendar(_getFilterType()),
            PaymentsFilterDropdown(
              _filter!,
              (value) {
                setState(() {
                  _filter = value?.toString();
                });
                final paymentsCubit = context.read<PaymentsCubit>();
                paymentsCubit.changePaymentFilter(
                  filters: _getFilterType(),
                  fromTimestamp: paymentsCubit.state.paymentFilters.fromTimestamp,
                  toTimestamp: paymentsCubit.state.paymentFilters.toTimestamp,
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<PaymentType> _getFilterType() {
    return _filterMap[_filter] ?? PaymentType.values;
  }

  String _getFilterTypeString(
    BuildContext context,
    List<PaymentType>? filterType,
  ) {
    for (var entry in _filterMap.entries) {
      if (entry.value == filterType) {
        return entry.key;
      }
    }
    final texts = context.texts();
    return texts.payments_filter_option_all;
  }
}
