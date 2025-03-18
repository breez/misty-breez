import 'package:flutter/material.dart';

/// Action keys that can be used in a numeric keypad
enum ActionKey {
  /// Biometric authentication with fingerprint
  fingerprint,

  /// Biometric authentication with face recognition
  faceId,

  /// Backspace (delete last character)
  backspace,

  /// Clear (delete all characters)
  clear,
}

/// Extension methods for ActionKey
extension ActionKeyExtension on ActionKey {
  /// Gets the icon for this action key
  IconData get icon {
    switch (this) {
      case ActionKey.fingerprint:
        return Icons.fingerprint;
      case ActionKey.faceId:
        return Icons.face;
      case ActionKey.backspace:
        return Icons.backspace;
      case ActionKey.clear:
        return Icons.delete_forever;
    }
  }
}
