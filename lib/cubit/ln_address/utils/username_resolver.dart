import 'package:breez_preferences/breez_preferences.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('UsernameResolver');

/// Responsible for resolving usernames from various sources according to priority rules.
///
/// This class implements a consistent strategy for determining which username to use
/// based on the available sources and the context.
class UsernameResolver {
  /// Preferences store used to retrieve and store username information
  final BreezPreferences breezPreferences;

  /// Creates a new UsernameResolver with the given preferences store
  ///
  /// @param breezPreferences The preferences store to use for username retrieval/storage
  UsernameResolver(this.breezPreferences);

  /// Resolves the appropriate username based on priority rules.
  ///
  /// Resolution priority:
  /// 1. Recovered lightning address username (if available)
  /// 2. Explicitly provided username (if available)
  /// 3. Stored username
  /// 4. Formatted profile name
  ///
  /// @param recoveredLightningAddress Optional recovered lightning address
  /// @param baseUsername Optional explicitly provided username
  /// @return The resolved username or null if no username could be determined
  Future<String?> resolveUsername({
    String? recoveredLightningAddress,
    String? baseUsername,
  }) async {
    try {
      _logger.info('Resolving username');

      // Try each resolution strategy in order of precedence
      final String? username = await _tryResolveFromRecoveredAddress(recoveredLightningAddress) ??
          _tryResolveFromProvidedUsername(baseUsername) ??
          await _tryResolveFromStoredUsername() ??
          await _tryResolveFromProfileName();

      if (username == null || username.isEmpty) {
        _logger.warning('Failed to resolve username using any strategy');
        return null;
      }
      return username;
    } catch (e, stackTrace) {
      _logger.severe('Error resolving username', e, stackTrace);
      // Return null on error - caller must handle this case
      return null;
    }
  }

  /// Priority 1: Extract username from recovered lightning address
  ///
  /// @param recoveredLightningAddress The recovered lightning address, if any
  /// @return The extracted username or null if not available
  Future<String?> _tryResolveFromRecoveredAddress(String? recoveredLightningAddress) async {
    if (recoveredLightningAddress?.isEmpty ?? true) {
      return null;
    }

    try {
      final String username = recoveredLightningAddress!.split('@').first;
      _logger.info('Using username from recovered Lightning Address: $username');
      return username;
    } catch (e) {
      _logger.warning('Failed to extract username from Lightning Address: $recoveredLightningAddress', e);
      return null;
    }
  }

  /// Priority 2: Use explicitly provided username
  ///
  /// @param baseUsername The explicitly provided username, if any
  /// @return The provided username or null if not available
  String? _tryResolveFromProvidedUsername(String? baseUsername) {
    if (baseUsername?.isEmpty ?? true) {
      return null;
    }

    _logger.info('Using explicitly provided username: $baseUsername');
    return baseUsername;
  }

  /// Priority 4: Format and use the user's profile name
  ///
  /// @return The formatted profile name or null if not available
  Future<String?> _tryResolveFromProfileName() async {
    try {
      final String? defaultProfileName = await breezPreferences.defaultProfileName;
      if (defaultProfileName?.isEmpty ?? true) {
        _logger.info('No default profile name available');
        return null;
      }

      final String formattedUsername = UsernameFormatter.formatDefaultProfileName(defaultProfileName!);
      _logger.info('Using formatted profile name: $formattedUsername');
      return formattedUsername;
    } catch (e) {
      _logger.warning('Error formatting profile name', e);
      return null;
    }
  }

  /// Priority 3: Retrieve previously stored username
  ///
  /// @return The stored username or null if not available
  Future<String?> _tryResolveFromStoredUsername() async {
    try {
      final String? storedUsername = await breezPreferences.lnAddressUsername;
      if (storedUsername?.isEmpty ?? true) {
        _logger.info('No previously stored username found');
        return null;
      }

      _logger.info('Using stored username: $storedUsername');
      return storedUsername;
    } catch (e) {
      _logger.warning('Error retrieving stored username', e);
      return null;
    }
  }
}
