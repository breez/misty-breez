import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

final _logger = Logger("PaymentFilterExporter");

class PaymentFilterExporter extends StatelessWidget {
  final List<PaymentType>? filter;

  const PaymentFilterExporter(this.filter, {super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, account) {
        return Padding(
          padding: const EdgeInsets.only(right: 0.0),
          child: PopupMenuButton(
            color: themeData.colorScheme.surface,
            icon: Icon(
              Icons.more_vert,
              color: themeData.paymentItemTitleTextStyle.color,
            ),
            padding: EdgeInsets.zero,
            offset: const Offset(12, 24),
            onSelected: _select,
            itemBuilder: (context) => [
              PopupMenuItem(
                height: 36,
                value: Choice(() => _exportPayments(context)),
                child: Text(
                  texts.payments_filter_action_export,
                  style: themeData.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _select(Choice choice) {
    choice.function();
  }

  Future _exportPayments(BuildContext context) async {
    final texts = context.texts();
    final navigator = Navigator.of(context);
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;
    final paymentsCubit = context.read<PaymentsCubit>();
    final paymentsState = paymentsCubit.state;
    var loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);
    String filePath;

    try {
      if (paymentsState.paymentFilters.fromTimestamp != null ||
          paymentsState.paymentFilters.toTimestamp != null) {
        final startDate = DateTime.fromMillisecondsSinceEpoch(paymentsState.paymentFilters.fromTimestamp!);
        final endDate = DateTime.fromMillisecondsSinceEpoch(paymentsState.paymentFilters.toTimestamp!);
        filePath =
            await CsvExporter(currencyState.fiatId, paymentsState, startDate: startDate, endDate: endDate)
                .export();
      } else {
        filePath = await CsvExporter(currencyState.fiatId, paymentsState).export();
      }
      if (loaderRoute.isActive) {
        navigator.removeRoute(loaderRoute);
      }
      Share.shareXFiles([XFile(filePath)]);
    } catch (error) {
      {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        _logger.severe("Received error: $error");
        if (!context.mounted) return;
        showFlushbar(
          context,
          message: texts.payments_filter_action_export_failed,
        );
      }
    } finally {
      if (loaderRoute.isActive) {
        navigator.removeRoute(loaderRoute);
      }
    }
  }
}

class Choice {
  const Choice(this.function);

  final Function function;
}
