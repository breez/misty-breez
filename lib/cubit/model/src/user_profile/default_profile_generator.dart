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

  return DefaultProfile(
    ProfileColor.pink.name(texts),
    ProfileAnimal.chick.name(texts),
  );
}
