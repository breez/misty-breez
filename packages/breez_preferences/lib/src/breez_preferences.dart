import 'package:breez_preferences/src/model/bug_report_behavior.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDefaultProportionalFee = 1.0;
const kDefaultExemptFeeMsat = 20000;
const kDefaultChannelSetupFeeLimitMsat = 5000000;

const _mempoolSpaceUrlKey = "mempool_space_url";
const _kPaymentOptionProportionalFee = "payment_options_proportional_fee";
const _kPaymentOptionExemptFee = "payment_options_exempt_fee";
const _kPaymentOptionChannelSetupFeeLimit = "payment_options_channel_setup_fee_limit";
const _kReportPrefKey = "report_preference_key";
const _kLnUrlPayKey = "lnurlpay_key";

final _logger = Logger("BreezPreferences");

class BreezPreferences {
  const BreezPreferences();

  Future<bool> hasPaymentOptions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().containsAll([
      _kPaymentOptionProportionalFee,
      _kPaymentOptionExemptFee,
      _kPaymentOptionChannelSetupFeeLimit,
    ]);
  }

  Future<String?> getMempoolSpaceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mempoolSpaceUrlKey);
  }

  Future<void> setMempoolSpaceUrl(String url) async {
    _logger.info("set mempool space url: $url");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mempoolSpaceUrlKey, url);
  }

  Future<void> resetMempoolSpaceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mempoolSpaceUrlKey);
  }

  Future<double> getPaymentOptionsProportionalFee() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kPaymentOptionProportionalFee) ?? kDefaultProportionalFee;
  }

  Future<void> setPaymentOptionsProportionalFee(double fee) async {
    _logger.info("set payment options proportional fee: $fee");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPaymentOptionProportionalFee, fee);
  }

  Future<int> getPaymentOptionsExemptFee() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPaymentOptionExemptFee) ?? kDefaultExemptFeeMsat;
  }

  Future<void> setPaymentOptionsExemptFee(int exemptFeeMsat) async {
    _logger.info("set payment options exempt fee : $exemptFeeMsat");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPaymentOptionExemptFee, exemptFeeMsat);
  }

  Future<int> getPaymentOptionsChannelSetupFeeLimitMsat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPaymentOptionChannelSetupFeeLimit) ?? kDefaultChannelSetupFeeLimitMsat;
  }

  Future<void> setPaymentOptionsChannelSetupFeeLimit(int channelFeeLimitMsat) async {
    _logger.info("set payment options channel setup limit fee : $channelFeeLimitMsat");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPaymentOptionChannelSetupFeeLimit, channelFeeLimitMsat);
    // iOS Extension requirement
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.setInt(_kPaymentOptionChannelSetupFeeLimit, channelFeeLimitMsat);
    }
  }

  Future<BugReportBehavior> getBugReportBehavior() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_kReportPrefKey);
    if (value == null || value < 0 || value >= BugReportBehavior.values.length) {
      return BugReportBehavior.prompt;
    }
    return BugReportBehavior.values[value];
  }

  Future<void> setBugReportBehavior(BugReportBehavior behavior) async {
    _logger.info("set bug report behavior: $behavior");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReportPrefKey, behavior.index);
  }

  Future<String?> getLnUrlPayKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLnUrlPayKey);
  }

  Future<void> setLnUrlPayKey(String webhookUrl) async {
    _logger.info("set lnurl pay key: $webhookUrl");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLnUrlPayKey, webhookUrl);
  }

  Future<void> resetLnUrlPayKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLnUrlPayKey);
  }
}
