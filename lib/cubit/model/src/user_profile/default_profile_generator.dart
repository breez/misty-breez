import 'dart:math';
import 'dart:ui';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:l_breez/cubit/cubit.dart';

class DefaultProfile {
  final String color;
  final String animal;

  const DefaultProfile(
    this.color,
    this.animal,
  );

  String buildName(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
      case 'fr':
      case 'it':
      case 'pt':
        return '$animal $color';

      case 'bg':
      case 'cs':
      case 'de':
      case 'el':
      case 'en':
      case 'fi':
      case 'sk':
      case 'sv':
      default:
        return '$color $animal';
    }
  }
}

DefaultProfile generateDefaultProfile() {
  final BreezTranslations texts = getSystemAppLocalizations();
  final Random random = Random();

  const List<ProfileColor> colors = ProfileColor.values;
  const List<ProfileAnimal> animals = ProfileAnimal.values;

  final ProfileColor randomColor = colors.elementAt(random.nextInt(colors.length));
  final ProfileAnimal randomAnimal = animals.elementAt(random.nextInt(animals.length));

  return DefaultProfile(
    randomColor.name(texts),
    randomAnimal.name(texts),
  );
}
