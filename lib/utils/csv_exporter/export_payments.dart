import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:share_plus/share_plus.dart';

final Logger _logger = Logger('ExportPayments');

/// Exports payments to CSV and shares the file.
Future<void> exportPayments(BuildContext context) async {
  if (!context.mounted) {
    _logger.warning('Context not mounted, aborting export');
    return;
  }

  final BreezTranslations texts = context.texts();
  final NavigatorState navigator = Navigator.of(context);
  final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);

  try {
    navigator.push(loaderRoute);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!context.mounted) {
      return;
    }

    final CurrencyState currencyState = context.read<CurrencyCubit>().state;
    final PaymentsState paymentsState = context.read<PaymentsCubit>().state;

    DateTime? startDate;
    DateTime? endDate;
    final int? fromTimestamp = paymentsState.paymentFilters.fromTimestamp;
    final int? toTimestamp = paymentsState.paymentFilters.toTimestamp;

    if (fromTimestamp != null && toTimestamp != null) {
      startDate = DateTime.fromMillisecondsSinceEpoch(fromTimestamp);
      endDate = DateTime.fromMillisecondsSinceEpoch(toTimestamp);
    }

    final CsvExporter exporter = CsvExporter(
      paymentsState,
      fiatCurrency: currencyState.fiatId,
      startDate: startDate,
      endDate: endDate,
    );

    final String filePath = await exporter.export();
    _logger.info('Payment export completed: $filePath');

    final ShareParams shareParams = ShareParams(title: 'Payments', files: <XFile>[XFile(filePath)]);
    await SharePlus.instance.share(shareParams);
  } catch (error, stackTrace) {
    _logger.severe('Failed to export payments', error, stackTrace);
    if (context.mounted) {
      showFlushbar(context, message: texts.payments_filter_action_export_failed);
    }
  } finally {
    if (loaderRoute.isActive) {
      navigator.removeRoute(loaderRoute);
    }
  }
}
