import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';

class CustomData {
  String loaderAssetPath;
  Color pendingTextColor;
  Color dashboardBgColor;
  Color paymentListBgColor;
  Color paymentListBgColorLight;
  Color navigationDrawerHeaderBgColor;
  Color surfaceBgColor;

  CustomData({
    required this.loaderAssetPath,
    required this.pendingTextColor,
    required this.dashboardBgColor,
    required this.paymentListBgColor,
    required this.paymentListBgColorLight,
    required this.navigationDrawerHeaderBgColor,
    required this.surfaceBgColor,
  });
}

final CustomData blueThemeCustomData = CustomData(
  loaderAssetPath: 'assets/animations/lottie/breez_loader.lottie',
  dashboardBgColor: Colors.white,
  pendingTextColor: const Color(0xff4D88EC),
  paymentListBgColor: const Color(0xFFf9f9f9),
  paymentListBgColorLight: Colors.white,
  surfaceBgColor: BreezColors.blue[500]!,
  navigationDrawerHeaderBgColor: const Color.fromRGBO(0, 103, 255, 1),
);

final CustomData darkThemeCustomData = CustomData(
  loaderAssetPath: 'assets/animations/lottie/breez_loader.lottie',
  pendingTextColor: const Color(0xff4D88EC),
  dashboardBgColor: const Color(0xFF00091c),
  paymentListBgColor: const Color.fromRGBO(10, 20, 40, 1),
  paymentListBgColorLight: const Color.fromRGBO(10, 20, 40, 1.33),
  surfaceBgColor: const Color.fromRGBO(10, 20, 40, 1),
  navigationDrawerHeaderBgColor: const Color(0xFF00091c),
);
