import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

/// Logger for the SdkVersionService class
final Logger _logger = Logger('SdkVersionService');

/// Service for retrieving SDK version information
class SdkVersionService {
  /// Private constructor to prevent instantiation
  SdkVersionService._();

  /// Package name for the Breez SDK
  static const String _packageName = 'flutter_breez_liquid';

  /// Default version string when version cannot be retrieved
  static const String _defaultVersion = 'Unknown';

  /// Local path indicator
  static const String _localPathIndicator = 'Dev Env';

  /// Retrieves the SDK version from pubspec.lock
  ///
  /// Returns a formatted version string containing version, branch, commit info,
  /// and source information (local path vs published)
  static Future<String> getSdkVersion() async {
    try {
      final String content = await rootBundle.loadString('pubspec.lock');
      final dynamic yamlContent = loadYaml(content);
      final dynamic package = yamlContent['packages']?[_packageName];

      if (package == null) {
        _logger.warning('Package $_packageName not found in pubspec.lock');
        return _defaultVersion;
      }

      return _formatVersionInfo(package);
    } catch (e) {
      _logger.severe('Failed to retrieve SDK version: $e');
      return '$_defaultVersion (Error: ${e.toString()})';
    }
  }

  /// Formats the version information from the package entry
  static String _formatVersionInfo(dynamic package) {
    final String? version = package['version'] as String?;
    final dynamic description = package['description'];
    String? branch;
    String? resolvedRef;
    bool isLocalPath = false;

    // Check if the package source is 'path' (local dependency)
    final String? source = package['source'] as String?;
    if (source == 'path') {
      isLocalPath = true;
    }

    // Extract information from description
    if (description is Map) {
      // For git dependencies
      if (description.containsKey('resolved-ref')) {
        resolvedRef = description['resolved-ref'] as String?;
      }
      if (description.containsKey('ref')) {
        branch = description['ref'] as String?;
      }
    }

    final List<String> versionParts = <String>[];

    if (version != null) {
      versionParts.add(version);
    }

    if (branch != null) {
      versionParts.add(branch);
    }

    if (resolvedRef != null) {
      versionParts.add(resolvedRef.substring(0, 7));
    }

    // Add local path indicator and path if available
    if (isLocalPath) {
      versionParts.add(_localPathIndicator);
    }

    return versionParts.join(' | ');
  }
}
