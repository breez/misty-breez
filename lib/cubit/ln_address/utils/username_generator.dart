import 'dart:math';

class UsernameGenerator {
  static const int _discriminatorLength = 4;
  static final Random _secureRandom = Random.secure();

  static String generateUsername(String baseUsername, int attempt) {
    if (attempt == 0) {
      return baseUsername;
    }

    final int discriminator = _secureRandom.nextInt(10000);
    final String formattedDiscriminator = discriminator.toString().padLeft(_discriminatorLength, '0');
    return '$baseUsername$formattedDiscriminator';
  }
}
