import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('MinFontSize');

/// Utility for calculating minimum font sizes based on device screen metrics
class MinFontSize {
  /// The build context to derive media query information
  final BuildContext context;

  /// The base font size to scale from
  final double? fontSize;

  /// Default minimum font size
  static const double _defaultFontSize = 12.0;

  /// Creates a new FontSizeCalculator
  ///
  /// [context] The build context for screen metrics
  /// [fontSize] Optional base font size (defaults to 12.0)
  MinFontSize(this.context, {this.fontSize});

  /// Calculates the minimum font size based on device text scaling
  ///
  /// Returns the scaled and floored font size
  double get minFontSize {
    final double baseSize = fontSize ?? _defaultFontSize;
    final double scaledSize = MediaQuery.of(context).textScaler.scale(baseSize);
    _logger.fine('Calculated min font size: $scaledSize from base: $baseSize');
    return scaledSize.floorToDouble();
  }
}
