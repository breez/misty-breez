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

enum ProfileColor {
  salmon,
  blue,
  turquoise,
  orchid,
  purple,
  tomato,
  cyan,
  crimson,
  orange,
  lime,
  pink,
  green,
  red,
  yellow,
  azure,
  silver,
  magenta,
  olive,
  violet,
  rose,
  wine,
  mint,
  indigo,
  jade,
  coral,
}

ProfileColor? profileColorFromName(String? name, BreezTranslations texts) {
  if (name == null) {
    return null;
  }
  final String key = name.toLowerCase();
  final Map<String, ProfileColor> localizedNames = _colorsFromName[texts.locale] ?? <String, ProfileColor>{};

  if (localizedNames.containsKey(key)) {
    return localizedNames[key];
  }

  for (Map<String, ProfileColor> map in _colorsFromName.values) {
    if (map.containsKey(key)) {
      return map[key];
    }
  }

  // Not a known color name
  return null;
}

extension ProfileColorExtension on ProfileColor {
  String name(BreezTranslations texts) {
    switch (this) {
      case ProfileColor.salmon:
        return texts.app_color_salmon;
      case ProfileColor.blue:
        return texts.app_color_blue;
      case ProfileColor.turquoise:
        return texts.app_color_turquoise;
      case ProfileColor.orchid:
        return texts.app_color_orchid;
      case ProfileColor.purple:
        return texts.app_color_purple;
      case ProfileColor.tomato:
        return texts.app_color_tomato;
      case ProfileColor.cyan:
        return texts.app_color_cyan;
      case ProfileColor.crimson:
        return texts.app_color_crimson;
      case ProfileColor.orange:
        return texts.app_color_orange;
      case ProfileColor.lime:
        return texts.app_color_lime;
      case ProfileColor.pink:
        return texts.app_color_pink;
      case ProfileColor.green:
        return texts.app_color_green;
      case ProfileColor.red:
        return texts.app_color_red;
      case ProfileColor.yellow:
        return texts.app_color_yellow;
      case ProfileColor.azure:
        return texts.app_color_azure;
      case ProfileColor.silver:
        return texts.app_color_silver;
      case ProfileColor.magenta:
        return texts.app_color_magenta;
      case ProfileColor.olive:
        return texts.app_color_olive;
      case ProfileColor.violet:
        return texts.app_color_violet;
      case ProfileColor.rose:
        return texts.app_color_rose;
      case ProfileColor.wine:
        return texts.app_color_wine;
      case ProfileColor.mint:
        return texts.app_color_mint;
      case ProfileColor.indigo:
        return texts.app_color_indigo;
      case ProfileColor.jade:
        return texts.app_color_jade;
      case ProfileColor.coral:
        return texts.app_color_coral;
    }
  }

  Color get color {
    switch (this) {
      case ProfileColor.salmon:
        return const Color(0xFFFA8072);
      case ProfileColor.blue:
        return const Color(0xFF4169E1);
      case ProfileColor.turquoise:
        return const Color(0xFF00CED1);
      case ProfileColor.orchid:
        return const Color(0xFF9932CC);
      case ProfileColor.purple:
        return const Color(0xFF800080);
      case ProfileColor.tomato:
        return const Color(0xFFFF6347);
      case ProfileColor.cyan:
        return const Color(0xFF008B8B);
      case ProfileColor.crimson:
        return const Color(0xFFDC143C);
      case ProfileColor.orange:
        return const Color(0xFFFFA500);
      case ProfileColor.lime:
        return const Color(0xFF32CD32);
      case ProfileColor.pink:
        return const Color(0xFFFF69B4);
      case ProfileColor.green:
        return const Color(0xFF00A644);
      case ProfileColor.red:
        return const Color(0xFFFF2727);
      case ProfileColor.yellow:
        return const Color(0xFFEECA0C);
      case ProfileColor.azure:
        return const Color(0xFF00C4FF);
      case ProfileColor.silver:
        return const Color(0xFF53687F);
      case ProfileColor.magenta:
        return const Color(0xFFFF00FF);
      case ProfileColor.olive:
        return const Color(0xFF808000);
      case ProfileColor.violet:
        return const Color(0xFF7F01FF);
      case ProfileColor.rose:
        return const Color(0xFFFF0080);
      case ProfileColor.wine:
        return const Color(0xFF950347);
      case ProfileColor.mint:
        return const Color(0xFF7ADEB8);
      case ProfileColor.indigo:
        return const Color(0xFF4B0082);
      case ProfileColor.jade:
        return const Color(0xFF00B27A);
      case ProfileColor.coral:
        return const Color(0xFFFF7F50);
    }
  }
}

Map<String, Map<String, ProfileColor>> _colorsFromName = <String, Map<String, ProfileColor>>{
  'bg': _buildColorsFromName(BreezTranslationsBg()),
  'cz': _buildColorsFromName(BreezTranslationsCs()),
  'cs': _buildColorsFromName(BreezTranslationsCs()),
  'de': _buildColorsFromName(BreezTranslationsDe()),
  'el': _buildColorsFromName(BreezTranslationsEl()),
  'en': _buildColorsFromName(BreezTranslationsEn()),
  'es': _buildColorsFromName(BreezTranslationsEs()),
  'fi': _buildColorsFromName(BreezTranslationsFi()),
  'fr': _buildColorsFromName(BreezTranslationsFr()),
  'it': _buildColorsFromName(BreezTranslationsIt()),
  'pt': _buildColorsFromName(BreezTranslationsPt()),
  'sk': _buildColorsFromName(BreezTranslationsSk()),
  'sv': _buildColorsFromName(BreezTranslationsSv()),
};

Map<String, ProfileColor> _buildColorsFromName(BreezTranslations local) => <String, ProfileColor>{
      local.app_color_salmon.toLowerCase(): ProfileColor.salmon,
      local.app_color_blue.toLowerCase(): ProfileColor.blue,
      local.app_color_turquoise.toLowerCase(): ProfileColor.turquoise,
      local.app_color_orchid.toLowerCase(): ProfileColor.orchid,
      local.app_color_purple.toLowerCase(): ProfileColor.purple,
      local.app_color_tomato.toLowerCase(): ProfileColor.tomato,
      local.app_color_cyan.toLowerCase(): ProfileColor.cyan,
      local.app_color_crimson.toLowerCase(): ProfileColor.crimson,
      local.app_color_orange.toLowerCase(): ProfileColor.orange,
      local.app_color_lime.toLowerCase(): ProfileColor.lime,
      local.app_color_pink.toLowerCase(): ProfileColor.pink,
      local.app_color_green.toLowerCase(): ProfileColor.green,
      local.app_color_red.toLowerCase(): ProfileColor.red,
      local.app_color_yellow.toLowerCase(): ProfileColor.yellow,
      local.app_color_azure.toLowerCase(): ProfileColor.azure,
      local.app_color_silver.toLowerCase(): ProfileColor.silver,
      local.app_color_magenta.toLowerCase(): ProfileColor.magenta,
      local.app_color_olive.toLowerCase(): ProfileColor.olive,
      local.app_color_violet.toLowerCase(): ProfileColor.violet,
      local.app_color_rose.toLowerCase(): ProfileColor.rose,
      local.app_color_wine.toLowerCase(): ProfileColor.wine,
      local.app_color_mint.toLowerCase(): ProfileColor.mint,
      local.app_color_indigo.toLowerCase(): ProfileColor.indigo,
      local.app_color_jade.toLowerCase(): ProfileColor.jade,
      local.app_color_coral.toLowerCase(): ProfileColor.coral,
    };
