import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
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
  Map<String, List<PaymentType>> _filterMap = <String, List<PaymentType>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filter = null;
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (BuildContext context, PaymentsState paymentsState) {
        if (_filter == null) {
          _filterMap = <String, List<PaymentType>>{
            texts.payments_filter_option_all: PaymentType.values,
            texts.payments_filter_option_sent: <PaymentType>[PaymentType.send],
            texts.payments_filter_option_received: <PaymentType>[PaymentType.receive],
          };
          _filter = _getFilterTypeString(
            context,
            paymentsState.paymentFilters.filters,
          );
        }

        return Row(
          children: <Widget>[
            PaymentFilterExporter(_getFilterType()),
            PaymentsFilterCalendar(_getFilterType()),
            PaymentsFilterDropdown(
              _filter!,
              (Object? value) {
                setState(() {
                  _filter = value?.toString();
                });
                final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
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
    for (MapEntry<String, List<PaymentType>> entry in _filterMap.entries) {
      if (entry.value == filterType) {
        return entry.key;
      }
    }
    final BreezTranslations texts = context.texts();
    return texts.payments_filter_option_all;
  }
}
