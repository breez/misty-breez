import 'package:breez_preferences/src/model/bug_report_behavior.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double kDefaultProportionalFee = 1.0;
const int kDefaultExemptFeeMsat = 20000;
const int kDefaultChannelSetupFeeLimitMsat = 5000000;

const String _mempoolSpaceUrlKey = 'mempool_space_url';
const String _kPaymentOptionProportionalFee = 'payment_options_proportional_fee';
const String _kPaymentOptionExemptFee = 'payment_options_exempt_fee';
const String _kPaymentOptionChannelSetupFeeLimit = 'payment_options_channel_setup_fee_limit';
const String _kReportPrefKey = 'report_preference_key';
const String _kLnUrlPayKey = 'lnurlpay_key';

final Logger _logger = Logger('BreezPreferences');

class BreezPreferences {
  const BreezPreferences();

  Future<bool> hasPaymentOptions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().containsAll(<Object?>[
      _kPaymentOptionProportionalFee,
      _kPaymentOptionExemptFee,
      _kPaymentOptionChannelSetupFeeLimit,
    ]);
  }

  Future<String?> getMempoolSpaceUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mempoolSpaceUrlKey);
  }

  Future<void> setMempoolSpaceUrl(String url) async {
    _logger.info('set mempool space url: $url');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mempoolSpaceUrlKey, url);
  }

  Future<void> resetMempoolSpaceUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mempoolSpaceUrlKey);
  }

  Future<double> getPaymentOptionsProportionalFee() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kPaymentOptionProportionalFee) ?? kDefaultProportionalFee;
  }

  Future<void> setPaymentOptionsProportionalFee(double fee) async {
    _logger.info('set payment options proportional fee: $fee');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPaymentOptionProportionalFee, fee);
  }

  Future<int> getPaymentOptionsExemptFee() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPaymentOptionExemptFee) ?? kDefaultExemptFeeMsat;
  }

  Future<void> setPaymentOptionsExemptFee(int exemptFeeMsat) async {
    _logger.info('set payment options exempt fee : $exemptFeeMsat');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPaymentOptionExemptFee, exemptFeeMsat);
  }

  Future<int> getPaymentOptionsChannelSetupFeeLimitMsat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPaymentOptionChannelSetupFeeLimit) ?? kDefaultChannelSetupFeeLimitMsat;
  }

  Future<void> setPaymentOptionsChannelSetupFeeLimit(int channelFeeLimitMsat) async {
    _logger.info('set payment options channel setup limit fee : $channelFeeLimitMsat');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPaymentOptionChannelSetupFeeLimit, channelFeeLimitMsat);
    // iOS Extension requirement
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.setInt(_kPaymentOptionChannelSetupFeeLimit, channelFeeLimitMsat);
    }
  }

  Future<BugReportBehavior> getBugReportBehavior() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? value = prefs.getInt(_kReportPrefKey);
    if (value == null || value < 0 || value >= BugReportBehavior.values.length) {
      return BugReportBehavior.prompt;
    }
    return BugReportBehavior.values[value];
  }

  Future<void> setBugReportBehavior(BugReportBehavior behavior) async {
    _logger.info('set bug report behavior: $behavior');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReportPrefKey, behavior.index);
  }

  Future<String?> getLnUrlPayKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLnUrlPayKey);
  }

  Future<void> setLnUrlPayKey(String webhookUrl) async {
    _logger.info('set lnurl pay key: $webhookUrl');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLnUrlPayKey, webhookUrl);
  }

  Future<void> resetLnUrlPayKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLnUrlPayKey);
  }
}
