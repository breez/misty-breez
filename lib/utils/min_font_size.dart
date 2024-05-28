import 'package:flutter/material.dart';

class MinFontSize {
  final BuildContext context;
  final double? fontSize;

  MinFontSize(this.context, {this.fontSize});

  double get minFontSize => MediaQuery.of(context).textScaler.scale((fontSize ?? 12)).floorToDouble();
}
