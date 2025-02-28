import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';

class CustomData {
  BlendMode loaderColorBlendMode;
  String loaderAssetPath;
  Color pendingTextColor;
  Color dashboardBgColor;
  Color paymentListBgColor;
  Color paymentListBgColorLight;
  Color navigationDrawerHeaderBgColor;
  Color navigationDrawerBgColor;

  CustomData({
    required this.loaderColorBlendMode,
    required this.loaderAssetPath,
    required this.pendingTextColor,
    required this.dashboardBgColor,
    required this.paymentListBgColor,
    required this.paymentListBgColorLight,
    required this.navigationDrawerHeaderBgColor,
    required this.navigationDrawerBgColor,
  });
}

final CustomData blueThemeCustomData = CustomData(
  loaderColorBlendMode: BlendMode.multiply,
  loaderAssetPath: 'assets/animations/breez_loader_blue.gif',
  dashboardBgColor: Colors.white,
  pendingTextColor: const Color(0xff4D88EC),
  paymentListBgColor: const Color(0xFFf9f9f9),
  paymentListBgColorLight: Colors.white,
  navigationDrawerBgColor: BreezColors.blue[500]!,
  navigationDrawerHeaderBgColor: const Color.fromRGBO(0, 103, 255, 1),
);

final CustomData darkThemeCustomData = CustomData(
  loaderColorBlendMode: BlendMode.multiply,
  loaderAssetPath: 'assets/animations/breez_loader_dark.gif',
  pendingTextColor: const Color(0xff4D88EC),
  dashboardBgColor: const Color(0xFF00091c),
  paymentListBgColor: const Color.fromRGBO(10, 20, 40, 1),
  paymentListBgColorLight: const Color.fromRGBO(10, 20, 40, 1.33),
  navigationDrawerBgColor: const Color.fromRGBO(10, 20, 40, 1),
  navigationDrawerHeaderBgColor: const Color(0xFF00091c),
);
