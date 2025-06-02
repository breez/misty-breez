import 'package:breez_translations/generated/breez_translations.dart';
import 'package:breez_translations/generated/breez_translations_bg.dart';
import 'package:breez_translations/generated/breez_translations_cs.dart';
import 'package:breez_translations/generated/breez_translations_de.dart';
import 'package:breez_translations/generated/breez_translations_el.dart';
import 'package:breez_translations/generated/breez_translations_en.dart';
import 'package:breez_translations/generated/breez_translations_es.dart';
import 'package:breez_translations/generated/breez_translations_fi.dart';
import 'package:breez_translations/generated/breez_translations_fr.dart';
import 'package:breez_translations/generated/breez_translations_it.dart';
import 'package:breez_translations/generated/breez_translations_pt.dart';
import 'package:breez_translations/generated/breez_translations_sk.dart';
import 'package:breez_translations/generated/breez_translations_sv.dart';
import 'package:flutter/material.dart';

enum ProfileAnimal {
  bat,
  bear,
  boar,
  cat,
  chick,
  cow,
  deer,
  dog,
  eagle,
  elephant,
  fox,
  frog,
  hippo,
  hummingbird,
  koala,
  lion,
  monkey,
  mouse,
  owl,
  ox,
  panda,
  pig,
  rabbit,
  seagull,
  sheep,
  snake,
}

ProfileAnimal? profileAnimalFromName(String? name, BreezTranslations texts) {
  if (name == null) {
    return null;
  }
  final String key = name.toLowerCase();
  final Map<String, ProfileAnimal> localizedNames =
      _animalsFromName[texts.locale] ?? <String, ProfileAnimal>{};

  if (localizedNames.containsKey(key)) {
    return localizedNames[key];
  }

  for (Map<String, ProfileAnimal> map in _animalsFromName.values) {
    if (map.containsKey(key)) {
      return map[key];
    }
  }

  // Not a known animal name
  return null;
}

extension ProfileAnimalExtension on ProfileAnimal {
  String name(BreezTranslations texts) {
    switch (this) {
      case ProfileAnimal.bat:
        return texts.app_animal_bat;
      case ProfileAnimal.bear:
        return texts.app_animal_bear;
      case ProfileAnimal.boar:
        return texts.app_animal_boar;
      case ProfileAnimal.cat:
        return texts.app_animal_cat;
      case ProfileAnimal.chick:
        return texts.app_animal_chick;
      case ProfileAnimal.cow:
        return texts.app_animal_cow;
      case ProfileAnimal.deer:
        return texts.app_animal_deer;
      case ProfileAnimal.dog:
        return texts.app_animal_dog;
      case ProfileAnimal.eagle:
        return texts.app_animal_eagle;
      case ProfileAnimal.elephant:
        return texts.app_animal_elephant;
      case ProfileAnimal.fox:
        return texts.app_animal_fox;
      case ProfileAnimal.frog:
        return texts.app_animal_frog;
      case ProfileAnimal.hippo:
        return texts.app_animal_hippo;
      case ProfileAnimal.hummingbird:
        return texts.app_animal_hummingbird;
      case ProfileAnimal.koala:
        return texts.app_animal_koala;
      case ProfileAnimal.lion:
        return texts.app_animal_lion;
      case ProfileAnimal.monkey:
        return texts.app_animal_monkey;
      case ProfileAnimal.mouse:
        return texts.app_animal_mouse;
      case ProfileAnimal.owl:
        return texts.app_animal_owl;
      case ProfileAnimal.ox:
        return texts.app_animal_ox;
      case ProfileAnimal.panda:
        return texts.app_animal_panda;
      case ProfileAnimal.pig:
        return texts.app_animal_pig;
      case ProfileAnimal.rabbit:
        return texts.app_animal_rabbit;
      case ProfileAnimal.seagull:
        return texts.app_animal_seagull;
      case ProfileAnimal.sheep:
        return texts.app_animal_sheep;
      case ProfileAnimal.snake:
        return texts.app_animal_snake;
    }
  }

  IconData get iconData {
    switch (this) {
      case ProfileAnimal.bat:
        return const IconData(0xe900, fontFamily: 'animals');
      case ProfileAnimal.bear:
        return const IconData(0xe901, fontFamily: 'animals');
      case ProfileAnimal.boar:
        return const IconData(0xe902, fontFamily: 'animals');
      case ProfileAnimal.cat:
        return const IconData(0xe903, fontFamily: 'animals');
      case ProfileAnimal.chick:
        return const IconData(0xe904, fontFamily: 'animals');
      case ProfileAnimal.cow:
        return const IconData(0xe905, fontFamily: 'animals');
      case ProfileAnimal.deer:
        return const IconData(0xe906, fontFamily: 'animals');
      case ProfileAnimal.dog:
        return const IconData(0xe907, fontFamily: 'animals');
      case ProfileAnimal.eagle:
        return const IconData(0xe908, fontFamily: 'animals');
      case ProfileAnimal.elephant:
        return const IconData(0xe909, fontFamily: 'animals');
      case ProfileAnimal.fox:
        return const IconData(0xe90a, fontFamily: 'animals');
      case ProfileAnimal.frog:
        return const IconData(0xe90b, fontFamily: 'animals');
      case ProfileAnimal.hippo:
        return const IconData(0xe90c, fontFamily: 'animals');
      case ProfileAnimal.hummingbird:
        return const IconData(0xe90d, fontFamily: 'animals');
      case ProfileAnimal.koala:
        return const IconData(0xe90e, fontFamily: 'animals');
      case ProfileAnimal.lion:
        return const IconData(0xe90f, fontFamily: 'animals');
      case ProfileAnimal.monkey:
        return const IconData(0xe910, fontFamily: 'animals');
      case ProfileAnimal.mouse:
        return const IconData(0xe911, fontFamily: 'animals');
      case ProfileAnimal.owl:
        return const IconData(0xe912, fontFamily: 'animals');
      case ProfileAnimal.ox:
        return const IconData(0xe913, fontFamily: 'animals');
      case ProfileAnimal.panda:
        return const IconData(0xe914, fontFamily: 'animals');
      case ProfileAnimal.pig:
        return const IconData(0xe915, fontFamily: 'animals');
      case ProfileAnimal.rabbit:
        return const IconData(0xe916, fontFamily: 'animals');
      case ProfileAnimal.seagull:
        return const IconData(0xe917, fontFamily: 'animals');
      case ProfileAnimal.sheep:
        return const IconData(0xe918, fontFamily: 'animals');
      case ProfileAnimal.snake:
        return const IconData(0xe919, fontFamily: 'animals');
    }
  }
}

Map<String, Map<String, ProfileAnimal>> _animalsFromName = <String, Map<String, ProfileAnimal>>{
  'bg': _buildAnimalsFromName(BreezTranslationsBg()),
  'cz': _buildAnimalsFromName(BreezTranslationsCs()),
  'cs': _buildAnimalsFromName(BreezTranslationsCs()),
  'de': _buildAnimalsFromName(BreezTranslationsDe()),
  'el': _buildAnimalsFromName(BreezTranslationsEl()),
  'en': _buildAnimalsFromName(BreezTranslationsEn()),
  'es': _buildAnimalsFromName(BreezTranslationsEs()),
  'fi': _buildAnimalsFromName(BreezTranslationsFi()),
  'fr': _buildAnimalsFromName(BreezTranslationsFr()),
  'it': _buildAnimalsFromName(BreezTranslationsIt()),
  'pt': _buildAnimalsFromName(BreezTranslationsPt()),
  'sk': _buildAnimalsFromName(BreezTranslationsSk()),
  'sv': _buildAnimalsFromName(BreezTranslationsSv()),
};

Map<String, ProfileAnimal> _buildAnimalsFromName(BreezTranslations local) => <String, ProfileAnimal>{
  local.app_animal_bat.toLowerCase(): ProfileAnimal.bat,
  local.app_animal_bear.toLowerCase(): ProfileAnimal.bear,
  local.app_animal_boar.toLowerCase(): ProfileAnimal.boar,
  local.app_animal_cat.toLowerCase(): ProfileAnimal.cat,
  local.app_animal_chick.toLowerCase(): ProfileAnimal.chick,
  local.app_animal_cow.toLowerCase(): ProfileAnimal.cow,
  local.app_animal_deer.toLowerCase(): ProfileAnimal.deer,
  local.app_animal_dog.toLowerCase(): ProfileAnimal.dog,
  local.app_animal_eagle.toLowerCase(): ProfileAnimal.eagle,
  local.app_animal_elephant.toLowerCase(): ProfileAnimal.elephant,
  local.app_animal_fox.toLowerCase(): ProfileAnimal.fox,
  local.app_animal_frog.toLowerCase(): ProfileAnimal.frog,
  local.app_animal_hippo.toLowerCase(): ProfileAnimal.hippo,
  local.app_animal_hummingbird.toLowerCase(): ProfileAnimal.hummingbird,
  local.app_animal_koala.toLowerCase(): ProfileAnimal.koala,
  local.app_animal_lion.toLowerCase(): ProfileAnimal.lion,
  local.app_animal_monkey.toLowerCase(): ProfileAnimal.monkey,
  local.app_animal_mouse.toLowerCase(): ProfileAnimal.mouse,
  local.app_animal_owl.toLowerCase(): ProfileAnimal.owl,
  local.app_animal_ox.toLowerCase(): ProfileAnimal.ox,
  local.app_animal_panda.toLowerCase(): ProfileAnimal.panda,
  local.app_animal_pig.toLowerCase(): ProfileAnimal.pig,
  local.app_animal_rabbit.toLowerCase(): ProfileAnimal.rabbit,
  local.app_animal_seagull.toLowerCase(): ProfileAnimal.seagull,
  local.app_animal_sheep.toLowerCase(): ProfileAnimal.sheep,
  local.app_animal_snake.toLowerCase(): ProfileAnimal.snake,
};
