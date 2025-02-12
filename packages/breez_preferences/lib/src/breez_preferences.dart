import 'package:breez_preferences/src/model/bug_report_behavior.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('BreezPreferences');

class BreezPreferences {
  // Preference Keys
  static const String _kBugReportBehavior = 'bug_report_behavior';
  static const String _kDefaultProfileName = 'default_profile_name';
  static const String _kWebhookUrl = 'webhook_url';
  static const String _kLnUrlWebhookRegistered = 'lnurl_webhook_registered';
  static const String _kLnAddressUsername = 'ln_address_username';

  const BreezPreferences();

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  // Bug Report Behavior
  Future<BugReportBehavior> get bugReportBehavior async {
    final SharedPreferences prefs = await _preferences;
    final int? value = prefs.getInt(_kBugReportBehavior);
    final BugReportBehavior behavior = BugReportBehavior.values[value ?? BugReportBehavior.prompt.index];

    _logger.info('Fetched BugReportBehavior: $behavior');
    return behavior;
  }

  Future<void> setBugReportBehavior(BugReportBehavior behavior) async {
    _logger.info('Setting BugReportBehavior: $behavior');
    final SharedPreferences prefs = await _preferences;
    await prefs.setInt(_kBugReportBehavior, behavior.index);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.setInt(_kBugReportBehavior, behavior.index);
    }
  }

  // Default Profile Name
  Future<String?> get defaultProfileName async {
    final SharedPreferences prefs = await _preferences;
    final String? defaultProfileName = prefs.getString(_kDefaultProfileName);

    _logger.info('Fetched Default Profile Name: $defaultProfileName');
    return defaultProfileName;
  }

  Future<void> setDefaultProfileName(String defaultProfileName) async {
    _logger.info('Setting Default Profile Name: $defaultProfileName');
    final SharedPreferences prefs = await _preferences;
    await prefs.setString(_kDefaultProfileName, defaultProfileName);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.setString(_kDefaultProfileName, _kDefaultProfileName);
    }
  }

  // Webhook URL
  Future<String?> get webhookUrl async {
    final SharedPreferences prefs = await _preferences;
    final String? url = prefs.getString(_kWebhookUrl);

    _logger.info('Fetched Webhook URL: $url');
    return url;
  }

  Future<void> setWebhookUrl(String webhookUrl) async {
    _logger.info('Setting Webhook URL: $webhookUrl');
    final SharedPreferences prefs = await _preferences;
    await prefs.setString(_kWebhookUrl, webhookUrl);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.setString(_kWebhookUrl, webhookUrl);
    }
  }

  Future<void> removeWebhookUrl() async {
    _logger.info('Removing Webhook URL');
    final SharedPreferences prefs = await _preferences;
    await prefs.remove(_kWebhookUrl);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.remove(_kWebhookUrl);
    }
  }

  // LN URL Webhook Registration
  Future<bool> get isLnUrlWebhookRegistered async {
    final SharedPreferences prefs = await _preferences;
    final bool registered = prefs.getBool(_kLnUrlWebhookRegistered) ?? false;

    _logger.info('LNURL Webhook Registered: $registered');
    return registered;
  }

  Future<void> setLnUrlWebhookRegistered() async {
    _logger.info('Setting LNURL Webhook as Registered');
    final SharedPreferences prefs = await _preferences;
    await prefs.setBool(_kLnUrlWebhookRegistered, true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.setBool(_kLnUrlWebhookRegistered, true);
    }
  }

  // LN Address Username
  Future<String?> get lnAddressUsername async {
    final SharedPreferences prefs = await _preferences;
    final String? username = prefs.getString(_kLnAddressUsername);

    _logger.info('Fetched LN Address Username: $username');
    return username;
  }

  Future<void> setLnAddressUsername(String lnAddressUsername) async {
    _logger.info('Setting LN Address Username: $lnAddressUsername');
    final SharedPreferences prefs = await _preferences;
    await prefs.setString(_kLnAddressUsername, lnAddressUsername);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SharedPreferenceAppGroup.setString(_kLnAddressUsername, lnAddressUsername);
    }
  }
}
