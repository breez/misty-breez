import 'package:breez_preferences/breez_preferences.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('UsernameResolver');

/// Resolution strategies in order of precedence
enum UsernameResolutionStrategy { recoveredAddress, providedUsername, profileName, storedUsername }

/// Responsible for resolving usernames from various sources according to priority rules.
///
/// This class implements a consistent strategy for determining which username to use
/// based on the available sources and the context (new registration vs. existing user).
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
  /// 3. Formatted profile name (for new registrations)
  /// 4. Stored username (for existing users)
  ///
  /// @param isNewRegistration Whether this is a new user registration
  /// @param recoveredLightningAddress Optional recovered lightning address
  /// @param baseUsername Optional explicitly provided username
  /// @return The resolved username or null if no username could be determined
  Future<String?> resolveUsername({
    required bool isNewRegistration,
    String? recoveredLightningAddress,
    String? baseUsername,
  }) async {
    try {
      _logger.info('Resolving username (isNewRegistration: $isNewRegistration)');

      // Try each resolution strategy in order of precedence
      final String? username = await _tryResolveFromRecoveredAddress(recoveredLightningAddress) ??
          _tryResolveFromProvidedUsername(baseUsername) ??
          (isNewRegistration ? await _tryResolveFromProfileName() : await _tryResolveFromStoredUsername());

      if (username == null || username.isEmpty) {
        _logger.warning('Failed to resolve username using any strategy');
      } else {
        _logger.info(
          'Successfully resolved username using strategy: ${_determineUsedStrategy(isNewRegistration: isNewRegistration, hasRecoveredAddress: recoveredLightningAddress != null && recoveredLightningAddress.isNotEmpty, hasProvidedUsername: baseUsername != null && baseUsername.isNotEmpty)}',
        );
      }

      return username;
    } catch (e, stackTrace) {
      _logger.severe('Error resolving username', e, stackTrace);
      // Return null on error - caller must handle this case
      return null;
    }
  }

  /// Determines which resolution strategy was used for logging purposes
  ///
  /// @return The strategy that was successfully used
  UsernameResolutionStrategy _determineUsedStrategy({
    required bool isNewRegistration,
    required bool hasRecoveredAddress,
    required bool hasProvidedUsername,
  }) {
    if (hasRecoveredAddress) {
      return UsernameResolutionStrategy.recoveredAddress;
    } else if (hasProvidedUsername) {
      return UsernameResolutionStrategy.providedUsername;
    } else if (isNewRegistration) {
      return UsernameResolutionStrategy.profileName;
    } else {
      return UsernameResolutionStrategy.storedUsername;
    }
  }

  /// Priority 1: Extract username from recovered lightning address
  ///
  /// @param recoveredLightningAddress The recovered lightning address, if any
  /// @return The extracted username or null if not available
  Future<String?> _tryResolveFromRecoveredAddress(String? recoveredLightningAddress) async {
    if (recoveredLightningAddress == null || recoveredLightningAddress.isEmpty) {
      return null;
    }

    try {
      final String username = recoveredLightningAddress.split('@').first;
      _logger.info('Extracted username from recovered Lightning Address: $username');
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
    if (baseUsername == null || baseUsername.isEmpty) {
      return null;
    }

    _logger.info('Using explicitly provided username: $baseUsername');
    return baseUsername;
  }

  /// Priority 3: Format and use the user's profile name
  ///
  /// @return The formatted profile name or null if not available
  Future<String?> _tryResolveFromProfileName() async {
    try {
      final String? defaultProfileName = await breezPreferences.defaultProfileName;

      if (defaultProfileName == null || defaultProfileName.isEmpty) {
        _logger.info('No default profile name available');
        return null;
      }

      final String formattedUsername = UsernameFormatter.formatDefaultProfileName(defaultProfileName);
      _logger.info('Formatted profile name to username: $formattedUsername');
      return formattedUsername;
    } catch (e) {
      _logger.warning('Error retrieving or formatting profile name', e);
      return null;
    }
  }

  /// Priority 4: Retrieve previously stored username
  ///
  /// @return The stored username or null if not available
  Future<String?> _tryResolveFromStoredUsername() async {
    try {
      final String? storedUsername = await breezPreferences.lnAddressUsername;

      if (storedUsername == null || storedUsername.isEmpty) {
        _logger.info('No previously stored username found');
      } else {
        _logger.info('Retrieved previously stored username: $storedUsername');
      }

      return storedUsername;
    } catch (e) {
      _logger.warning('Error retrieving stored username', e);
      return null;
    }
  }
}
