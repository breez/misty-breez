import 'dart:math';

import 'package:logging/logging.dart';

Logger _logger = Logger('UsernameGenerator');

/// A utility class for generating usernames with optional random discriminators.
///
/// Used when creating a new wallet to generate default profile usernames.
/// Example flow: "Red Panda" => "redpanda" -> "redpanda0231" -> "redpanda7439"
class UsernameGenerator {
  /// The length of the random discriminator to append to usernames
  static const int _discriminatorLength = 4;

  /// Maximum possible discriminator value (10^_discriminatorLength - 1)
  static const int _maxDiscriminatorValue = 10000;

  /// Secure random number generator for discriminator values
  static final Random _secureRandom = Random.secure();

  /// Generates a username, optionally with a random discriminator.
  ///
  /// Takes a base username and an attempt counter to handle name collisions.
  /// - If attempt is 0, returns the base username as-is.
  /// - If attempt > 0, appends a random 4-digit discriminator.
  ///
  /// @param baseUsername The core username to use
  /// @param attempt The current generation attempt (0 = no discriminator)
  /// @return A username string, with discriminator if attempt > 0
  static String generateUsername(String baseUsername, int attempt) {
    _validateInputParameters(baseUsername, attempt);

    // Return base username on first attempt
    if (attempt == 0) {
      _logger.info('First attempt. Using base username: $baseUsername');
      return baseUsername;
    }

    // Generate a unique discriminator and format the username
    try {
      return _generateUsernameWithDiscriminator(baseUsername);
    } catch (e) {
      _logger.severe('Error generating username. Attempting to re-generate username.', e);
      return _generateUsernameWithDiscriminator(baseUsername);
    }
  }

  /// Validates input parameters for username generation.
  ///
  /// @throws ArgumentError if validation fails
  static void _validateInputParameters(String baseUsername, int attempt) {
    if (baseUsername.isEmpty) {
      const String message = 'Base username cannot be empty';
      _logger.warning(message);
      throw ArgumentError(message);
    }

    if (attempt < 0) {
      final String message = 'Attempt number cannot be negative: $attempt';
      _logger.warning(message);
      throw ArgumentError(message);
    }
  }

  /// Generates a unique discriminator not previously used for this base username.
  ///
  /// Implements collision avoidance by tracking previously used values.
  /// @param baseUsername The username to generate a discriminator for
  /// @return A unique integer discriminator
  static int _generateUniqueDiscriminator() => _secureRandom.nextInt(_maxDiscriminatorValue);

  /// Generates a username with its discriminator.
  ///
  /// @param baseUsername The core username
  /// @return Formatted username with padded discriminator
  static String _generateUsernameWithDiscriminator(String baseUsername) {
    final String discriminatorStr = _generateUniqueDiscriminator().toString();
    final String formattedDiscriminator = discriminatorStr.padLeft(_discriminatorLength, '0');
    final String generatedUsername = '$baseUsername$formattedDiscriminator';
    _logger.info('Generated username: $generatedUsername');
    return generatedUsername;
  }
}
