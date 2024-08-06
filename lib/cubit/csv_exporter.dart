import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:csv/csv.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:intl/intl.dart';
import 'package:l_breez/cubit/payments/payments_state.dart';
import 'package:l_breez/utils/date.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger("CsvExporter");

class CsvExporter {
  final PaymentsState paymentsState;
  final bool usesUtcTime;
  final String fiatCurrency;
  final DateTime? startDate;
  final DateTime? endDate;

  CsvExporter(
    this.fiatCurrency,
    this.paymentsState, {
    this.usesUtcTime = false,
    this.startDate,
    this.endDate,
  });

  Future<String> export() async {
    _log.info("export payments started");
    String tmpFilePath =
        await _saveCsvFile(const ListToCsvConverter().convert(_generateList() as List<List>));
    _log.info("export payments finished");
    return tmpFilePath;
  }

  List _generateList() {
    // Fetch CurrencyState map values accordingly
    _log.info("generating payment list started");
    final texts = getSystemAppLocalizations();
    final filteredPayments = paymentsState.filteredPayments;
    List<List<String>> paymentList = List.generate(filteredPayments.length, (index) {
      List<String> paymentItem = [];
      final data = filteredPayments.elementAt(index);
      final paymentInfo = data;
      paymentItem.add(BreezDateUtils.formatYearMonthDayHourMinute(paymentInfo.paymentTime));
      paymentItem.add(paymentInfo.title);
      paymentItem.add(paymentInfo.amountSat.toString());
      paymentItem.add(paymentInfo.preimage);
      paymentItem.add(paymentInfo.id);
      paymentItem.add(paymentInfo.feeSat.toString());
      return paymentItem;
    });
    paymentList.insert(0, [
      texts.csv_exporter_date_and_time,
      texts.csv_exporter_title,
      texts.csv_exporter_amount,
      texts.csv_exporter_preimage,
      texts.csv_exporter_tx_hash,
      texts.csv_exporter_fee,
    ]);
    _log.info("generating payment finished");
    return paymentList;
  }

  Future<String> _saveCsvFile(String csv) async {
    _log.info("save breez payments to csv started");
    String filePath = await _createCsvFilePath();
    final file = File(filePath);
    await file.writeAsString(csv);
    _log.info("save breez payments to csv finished");
    return file.path;
  }

  Future<String> _createCsvFilePath() async {
    _log.info("create breez payments path started");
    final directory = await getTemporaryDirectory();
    String filePath = '${directory.path}/BreezPayments';
    filePath = _appendFilterInformation(filePath);
    filePath += ".csv";
    _log.info("create breez payments path finished");
    return filePath;
  }

  String _appendFilterInformation(String filePath) {
    _log.info("add filter information to path started $filePath");
    final paymentTypeFilters = paymentsState.paymentFilters.filters;
    if (paymentTypeFilters != null && paymentTypeFilters != PaymentType.values) {
      loop:
      for (var filter in paymentTypeFilters) {
        switch (filter) {
          case PaymentType.send:
            filePath += "_sent";
            break loop;
          case PaymentType.receive:
            filePath += "_received";
            break loop;
        }
      }
    }
    if (startDate != null && endDate != null) {
      DateFormat dateFilterFormat = DateFormat("d.M.yy");
      String dateFilter = '${dateFilterFormat.format(startDate!)}-${dateFilterFormat.format(endDate!)}';
      filePath += "_$dateFilter";
    }
    _log.info("add filter information to path finished");
    return filePath;
  }
}
