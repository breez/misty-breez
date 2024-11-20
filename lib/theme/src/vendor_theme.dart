import 'dart:ui';

class VendorTheme {
  final Color iconBgColor;
  final Color? iconFgColor;
  final Color? textColor;

  VendorTheme({required this.iconBgColor, this.iconFgColor, this.textColor});
}

final VendorTheme bitrefill = VendorTheme(
  iconFgColor: const Color.fromRGBO(68, 155, 247, 1.0),
  iconBgColor: const Color(0xFFffffff),
  textColor: const Color.fromRGBO(47, 47, 47, 1.0),
);
final VendorTheme lnpizza = VendorTheme(
  iconBgColor: const Color(0xFF000000),
  iconFgColor: const Color(0xFFf8e71c),
);
final VendorTheme fixedfloat = VendorTheme(iconBgColor: const Color(0xFF0B4E7B));
final VendorTheme lnmarkets = VendorTheme(
  iconBgColor: const Color(0xFF0a157a),
  textColor: const Color(0xFFe2ded5),
);
final VendorTheme boltz = VendorTheme(iconBgColor: const Color(0xFF001524));
final VendorTheme lightnite = VendorTheme(iconBgColor: const Color(0xFF530709));
final VendorTheme spendl = VendorTheme(iconBgColor: const Color(0xFFffffff));
final VendorTheme kollider = VendorTheme(
  iconBgColor: const Color.fromRGBO(21, 23, 25, 1),
  iconFgColor: const Color.fromRGBO(217, 227, 234, 1),
  textColor: const Color.fromRGBO(217, 227, 234, 1),
);
final VendorTheme fastbitcoins = VendorTheme(
  iconBgColor: const Color(0xFFff7c10),
  iconFgColor: const Color(0xFF1f2a44),
  textColor: const Color(0xFF1f2a44),
);
final VendorTheme xsats = VendorTheme(iconBgColor: const Color(0xFF000000));

final Map<String, VendorTheme> vendorTheme = <String, VendorTheme>{
  'bitrefill': bitrefill,
  'ln.pizza': lnpizza,
  'fixedfloat': fixedfloat,
  'lnmarkets': lnmarkets,
  'boltz': boltz,
  'lightnite': lightnite,
  'spendl': spendl,
  'kollider': kollider,
  'fastbitcoins': fastbitcoins,
  'xsats': xsats,
};
