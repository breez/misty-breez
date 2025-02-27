import 'package:breez_preferences/breez_preferences.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('UsernameResolver');

class UsernameResolver {
  final BreezPreferences breezPreferences;

  UsernameResolver(this.breezPreferences);

  Future<String?> resolveUsername({
    required bool isNewRegistration,
    String? recoveredLightningAddress,
    String? baseUsername,
  }) async {
    // Priority 1: Recovered lightning address username
    if (recoveredLightningAddress != null && recoveredLightningAddress.isNotEmpty) {
      final String username = recoveredLightningAddress.split('@').first;
      _logger.info('Using username from recovered Lightning Address: $username');
      return username;
    }

    // Priority 2: Explicitly provided username (for updates)
    if (baseUsername != null && baseUsername.isNotEmpty) {
      _logger.info('Using provided baseUsername: $baseUsername');
      return baseUsername;
    }

    // Priority 3: For new registrations, use profile name
    if (isNewRegistration) {
      final String? defaultProfileName = await breezPreferences.defaultProfileName;
      final String formattedUsername = UsernameFormatter.formatDefaultProfileName(defaultProfileName);
      _logger.info('Using formatted profile name: $formattedUsername');
      return formattedUsername;
    }

    // Priority 4: For existing registrations, use stored username
    final String? storedUsername = await breezPreferences.lnAddressUsername;
    _logger.info('Using stored username: $storedUsername');
    return storedUsername;
  }
}
