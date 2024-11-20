import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:csv/csv.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:intl/intl.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/payment_details_extension.dart';
import 'package:l_breez/utils/date.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final Logger _logger = Logger('CsvExporter');

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
    _logger.info('export payments started');
    final String tmpFilePath = await _saveCsvFile(const ListToCsvConverter().convert(_generateList()));
    _logger.info('export payments finished');
    return tmpFilePath;
  }

  List<List<String>> _generateList() {
    // Fetch CurrencyState map values accordingly
    _logger.info('generating payment list started');
    final BreezTranslations texts = getSystemAppLocalizations();
    final List<PaymentData> filteredPayments = paymentsState.filteredPayments;
    final List<List<String>> paymentList = List<List<String>>.generate(filteredPayments.length, (int index) {
      final List<String> paymentItem = <String>[];
      final PaymentData data = filteredPayments.elementAt(index);
      final PaymentData paymentInfo = data;
      paymentItem.add(BreezDateUtils.formatYearMonthDayHourMinute(paymentInfo.paymentTime));
      paymentItem.add(paymentInfo.title);
      paymentItem.add(paymentInfo.amountSat.toString());
      // TODO(erdemyerebasmaz): Add other payment details necessary for liquid & BTC payments.
      paymentItem.add(_getPreimage(paymentInfo));
      paymentItem.add(paymentInfo.id);
      paymentItem.add(paymentInfo.feeSat.toString());
      return paymentItem;
    });
    paymentList.insert(0, <String>[
      texts.csv_exporter_date_and_time,
      texts.csv_exporter_title,
      texts.csv_exporter_amount,
      texts.csv_exporter_preimage,
      texts.csv_exporter_tx_hash,
      texts.csv_exporter_fee,
    ]);
    _logger.info('generating payment finished');
    return paymentList;
  }

  Future<String> _saveCsvFile(String csv) async {
    _logger.info('save breez payments to csv started');
    final String filePath = await _createCsvFilePath();
    final File file = File(filePath);
    await file.writeAsString(csv);
    _logger.info('save breez payments to csv finished');
    return file.path;
  }

  Future<String> _createCsvFilePath() async {
    _logger.info('create breez payments path started');
    final Directory directory = await getTemporaryDirectory();
    String filePath = '${directory.path}/BreezPayments';
    filePath = _appendFilterInformation(filePath);
    filePath += '.csv';
    _logger.info('create breez payments path finished');
    return filePath;
  }

  String _appendFilterInformation(String filePath) {
    _logger.info('add filter information to path started $filePath');
    final List<PaymentType>? paymentTypeFilters = paymentsState.paymentFilters.filters;
    if (paymentTypeFilters != null && paymentTypeFilters != PaymentType.values) {
      loop:
      for (PaymentType filter in paymentTypeFilters) {
        switch (filter) {
          case PaymentType.send:
            filePath += '_sent';
            break loop;
          case PaymentType.receive:
            filePath += '_received';
            break loop;
        }
      }
    }
    if (startDate != null && endDate != null) {
      final DateFormat dateFilterFormat = DateFormat('d.M.yy');
      final String dateFilter = '${dateFilterFormat.format(startDate!)}-${dateFilterFormat.format(endDate!)}';
      filePath += '_$dateFilter';
    }
    _logger.info('add filter information to path finished');
    return filePath;
  }

  String _getPreimage(PaymentData paymentInfo) {
    return paymentInfo.details.map(
          lightning: (PaymentDetails_Lightning details) => details.preimage,
          orElse: () => '',
        ) ??
        '';
  }
}
