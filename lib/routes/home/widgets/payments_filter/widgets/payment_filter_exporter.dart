import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

final Logger _logger = Logger('PaymentFilterExporter');

class PaymentFilterExporter extends StatelessWidget {
  final List<PaymentType>? filter;

  const PaymentFilterExporter(this.filter, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (BuildContext context, AccountState account) {
        return Padding(
          padding: const EdgeInsets.only(),
          child: PopupMenuButton<PaymentFilterChoice>(
            color: themeData.colorScheme.surface,
            icon: Icon(
              Icons.more_vert,
              color: themeData.paymentItemTitleTextStyle.color,
            ),
            padding: EdgeInsets.zero,
            offset: const Offset(12, 24),
            onSelected: _select,
            itemBuilder: (BuildContext context) => <PopupMenuItem<PaymentFilterChoice>>[
              PopupMenuItem<PaymentFilterChoice>(
                height: 36,
                value: PaymentFilterChoice(() => _exportPayments(context)),
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

  void _select(PaymentFilterChoice choice) {
    choice.function();
  }

  Future<void> _exportPayments(BuildContext context) async {
    final BreezTranslations texts = context.texts();
    final NavigatorState navigator = Navigator.of(context);
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    final PaymentsState paymentsState = paymentsCubit.state;
    final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
    navigator.push(loaderRoute);
    String filePath;

    try {
      if (paymentsState.paymentFilters.fromTimestamp != null ||
          paymentsState.paymentFilters.toTimestamp != null) {
        final DateTime startDate =
            DateTime.fromMillisecondsSinceEpoch(paymentsState.paymentFilters.fromTimestamp!);
        final DateTime endDate =
            DateTime.fromMillisecondsSinceEpoch(paymentsState.paymentFilters.toTimestamp!);
        filePath =
            await CsvExporter(currencyState.fiatId, paymentsState, startDate: startDate, endDate: endDate)
                .export();
      } else {
        filePath = await CsvExporter(currencyState.fiatId, paymentsState).export();
      }
      if (loaderRoute.isActive) {
        navigator.removeRoute(loaderRoute);
      }
      Share.shareXFiles(<XFile>[XFile(filePath)]);
    } catch (error) {
      {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        _logger.severe('Received error: $error');
        if (!context.mounted) {
          return;
        }
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

class PaymentFilterChoice {
  const PaymentFilterChoice(this.function);

  final Function function;
}
