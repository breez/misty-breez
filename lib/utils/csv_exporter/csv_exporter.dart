import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:csv/csv.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:path_provider/path_provider.dart';

export 'export_payments.dart';

final Logger _logger = Logger('CsvExporter');

/// Exports payment data to CSV format.
class CsvExporter {
  final PaymentsState paymentsState;
  final String fiatCurrency;
  final DateTime? startDate;
  final DateTime? endDate;

  const CsvExporter(this.paymentsState, {required this.fiatCurrency, this.startDate, this.endDate});

  /// Exports payments to a CSV file and returns the file path.
  Future<String> export() async {
    _logger.info('Starting CSV export');

    try {
      final List<List<String>> csvData = _generateCsvData();
      final String csvContent = const ListToCsvConverter().convert(csvData);
      final String filePath = await _saveCsvFile(csvContent);

      _logger.info('CSV export completed: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      _logger.severe('CSV export failed', e, stackTrace);
      rethrow;
    }
  }

  /// Generates CSV data from payment records.
  List<List<String>> _generateCsvData() {
    final BreezTranslations texts = getSystemAppLocalizations();
    final List<PaymentData> payments = paymentsState.filteredPayments;
    final List<List<String>> csvRows = <List<String>>[
      <String>[
        texts.csv_exporter_date_and_time,
        texts.csv_exporter_title,
        'Status',
        'Type',
        texts.csv_exporter_amount,
        texts.csv_exporter_fee,
        'Refund Amount',
        texts.csv_exporter_preimage,
        texts.csv_exporter_tx_hash,
      ],
    ];

    for (final PaymentData payment in payments) {
      final bool isSend = payment.paymentType == PaymentType.send;
      final int amountMultiplier = isSend ? -1 : 1;

      csvRows.add(<String>[
        BreezDateUtils.formatYearMonthDayHourMinute(payment.paymentTime),
        payment.title,
        payment.isRefunded ? 'refunded' : payment.status.name,
        payment.paymentType.name,
        (payment.amountSat * amountMultiplier).toString(),
        (payment.feeSat * amountMultiplier).toString(),
        payment.refundTxAmountSat.toString(),
        payment.preimage,
        payment.id,
      ]);
    }

    _logger.info('Generated CSV data for ${payments.length} payments');
    return csvRows;
  }

  /// Saves CSV content to a temporary file.
  Future<String> _saveCsvFile(String csvContent) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = _buildFileName();
    final String filePath = '${tempDir.path}/$fileName';

    final File file = File(filePath);
    await file.writeAsString(csvContent);

    _logger.fine('$fileName saved to: $filePath');
    return filePath;
  }

  /// Builds the file name with filter information.
  String _buildFileName() {
    final StringBuffer name = StringBuffer('BreezPayments');

    if (paymentsState.paymentFilters.hasTypeFilters) {
      final List<PaymentType>? filters = paymentsState.paymentFilters.filters;
      if (filters != null && filters.isNotEmpty) {
        if (filters.contains(PaymentType.send)) {
          name.write('_sent');
        } else if (filters.contains(PaymentType.receive)) {
          name.write('_received');
        }
      }
    }

    if (startDate != null && endDate != null) {
      final DateFormat formatter = DateFormat('d.M.yy');
      name.write('_${formatter.format(startDate!)}-${formatter.format(endDate!)}');
    }

    name.write('.csv');
    return name.toString();
  }
}
