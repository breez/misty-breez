import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:l_breez/cubit/account/account_state.dart';
import 'package:l_breez/cubit/csv_exporter.dart';
import 'package:l_breez/cubit/currency/currency_cubit.dart';
import 'package:l_breez/theme/theme_provider.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

class PaymentFilterExporter extends StatelessWidget {
  final _log = Logger("PaymentmentFilterExporter");
  final List<PaymentType>? filter;

  PaymentFilterExporter(this.filter, {super.key});

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
    final currencyState = context.read<CurrencyCubit>().state;
    final accountCubit = context.read<AccountCubit>();
    final accountState = accountCubit.state;
    var loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);
    String filePath;

    try {
      if (accountState.paymentFilters.fromTimestamp != null ||
          accountState.paymentFilters.toTimestamp != null) {
        final startDate = DateTime.fromMillisecondsSinceEpoch(accountState.paymentFilters.fromTimestamp!);
        final endDate = DateTime.fromMillisecondsSinceEpoch(accountState.paymentFilters.toTimestamp!);
        filePath =
            await CsvExporter(currencyState.fiatId, accountCubit, startDate: startDate, endDate: endDate)
                .export();
      } else {
        filePath = await CsvExporter(currencyState.fiatId, accountCubit).export();
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
        _log.severe("Received error: $error");
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
