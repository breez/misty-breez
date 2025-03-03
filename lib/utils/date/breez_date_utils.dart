import 'dart:io' show Platform;

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:intl/intl.dart';
import 'package:l_breez/utils/constants/app_constants.dart';
import 'package:logging/logging.dart';
import 'package:timeago/timeago.dart' as timeago;

final Logger _logger = Logger('BreezDateUtils');

/// Utility class for date formatting and calculations
class BreezDateUtils {
  /// Private constructor to prevent instantiation
  BreezDateUtils._();

  /// Date format for month and day
  static final DateFormat _monthDateFormat = DateFormat.Md(Platform.localeName);

  /// Date format for year, month, and day
  static final DateFormat _yearMonthDayFormat = DateFormat.yMd(Platform.localeName);

  /// Date format for year, month, day, hour, and minute
  static final DateFormat _yearMonthDayHourMinuteFormat = DateFormat.yMd(Platform.localeName).add_jm();

  /// Date format for year, month, day, hour, minute, and second
  static final DateFormat _yearMonthDayHourMinuteSecondFormat = DateFormat.yMd(Platform.localeName).add_Hms();

  /// Date format for hour and minute
  static final DateFormat _hourMinuteDayFormat = DateFormat.jm(Platform.localeName);

  /// Formats a date as month and day
  static String formatMonthDate(DateTime d) => _monthDateFormat.format(d);

  /// Formats a date as year, month, and day
  static String formatYearMonthDay(DateTime d) => _yearMonthDayFormat.format(d);

  /// Formats a date as year, month, day, hour, and minute
  static String formatYearMonthDayHourMinute(DateTime d) => _yearMonthDayHourMinuteFormat
      .format(d)
      // Known issues: NumberFormat Non-breaking space breaking unit tests
      // TODO(erdemyerebasmaz): remove it when a fix is published  https://github.com/dart-lang/i18n/issues/146
      .replaceAll(' ', ' ');

  /// Formats a date as year, month, day, hour, minute, and second
  static String formatYearMonthDayHourMinuteSecond(DateTime d) =>
      _yearMonthDayHourMinuteSecondFormat.format(d);

  /// Formats a date for timelines, using relative time for recent dates
  static String formatTimelineRelative(DateTime d) {
    if (DateTime.now().subtract(const Duration(days: 4)).isBefore(d)) {
      return timeago.format(d, locale: getSystemLocale().languageCode);
    } else {
      return formatYearMonthDay(d);
    }
  }

  /// Checks if a date is between two other dates
  ///
  /// [date] The date to check
  /// [fromDateTime] The start date of the range
  /// [toDateTime] The end date of the range
  /// Returns true if the date is between the two dates
  static bool isBetween(
    DateTime date,
    DateTime fromDateTime,
    DateTime toDateTime,
  ) {
    final bool isAfter = date.isAfter(fromDateTime);
    final bool isBefore = date.isBefore(toDateTime);
    return isAfter && isBefore;
  }

  /// Calculates a date based on current blockheight and expiry blockheight
  ///
  /// [blockHeight] Current block height
  /// [expiryBlock] Expiry block height
  /// [secondsPerBlock] Average seconds per block for the blockchain
  /// Returns an estimated expiry date or null if parameters are invalid
  static DateTime? _blockDiffToDate({
    required int? blockHeight,
    required int? expiryBlock,
    required int secondsPerBlock,
  }) {
    if (blockHeight == null || expiryBlock == null || blockHeight > expiryBlock) {
      _logger.fine('Invalid block parameters: height=$blockHeight, expiry=$expiryBlock');
      return null;
    }

    final int diffInSecs = (expiryBlock - blockHeight) * secondsPerBlock;
    final DateTime time = DateTime.now();
    return time.add(Duration(seconds: diffInSecs));
  }

  /// Calculates an estimated date from Bitcoin block heights
  ///
  /// [blockHeight] Current Bitcoin block height
  /// [expiryBlock] Expiry Bitcoin block height
  /// Returns an estimated expiry date or null if parameters are invalid
  static DateTime? bitcoinBlockDiffToDate({
    required int? blockHeight,
    required int? expiryBlock,
  }) {
    return _blockDiffToDate(
      blockHeight: blockHeight,
      expiryBlock: expiryBlock,
      secondsPerBlock: BlockTimes.bitcoinBlockTimeSeconds,
    );
  }

  /// Calculates an estimated date from Liquid block heights
  ///
  /// [blockHeight] Current Liquid block height
  /// [expiryBlock] Expiry Liquid block height
  /// Returns an estimated expiry date or null if parameters are invalid
  static DateTime? liquidBlockDiffToDate({
    required int? blockHeight,
    required int? expiryBlock,
  }) {
    return _blockDiffToDate(
      blockHeight: blockHeight,
      expiryBlock: expiryBlock,
      secondsPerBlock: BlockTimes.liquidBlockTimeSeconds,
    );
  }

  /// Formats a date as hour and minute
  static String formatHourMinute(DateTime d) => _hourMinuteDayFormat.format(d);

  /// Formats a date range for use in filters
  ///
  /// [startDate] Start date of the range
  /// [endDate] End date of the range
  /// Returns a formatted date range string
  static String formatFilterDateRange(DateTime startDate, DateTime endDate) {
    final DateFormat formatter = (startDate.year == endDate.year) ? _monthDateFormat : _yearMonthDayFormat;
    return '${formatter.format(startDate)}-${formatter.format(endDate)}';
  }

  /// Sets up locale messages for the timeago package
  static void setupLocales() {
    _logger.info('Setting up timeago locales');
    timeago.setLocaleMessages('bg', timeago.EnMessages()); // TODO(erdemyerebasmaz): add bg locale
    timeago.setLocaleMessages('cs', timeago.CsMessages());
    timeago.setLocaleMessages('de', timeago.DeMessages());
    timeago.setLocaleMessages('el', timeago.GrMessages());
    timeago.setLocaleMessages('en', timeago.EnMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());
    timeago.setLocaleMessages('fi', timeago.FiMessages());
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    timeago.setLocaleMessages('it', timeago.ItMessages());
    timeago.setLocaleMessages('pt', timeago.PtBrMessages());
    timeago.setLocaleMessages('sk', timeago.EnMessages()); // TODO(erdemyerebasmaz): add sk locale
    timeago.setLocaleMessages('sv', timeago.SvMessages());
  }
}
