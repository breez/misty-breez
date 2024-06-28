# Preserve Flutter Wrapper code
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# To ignore minifyEnabled: true error
# https://github.com/flutter/flutter/issues/19250
# https://github.com/flutter/flutter/issues/37441
-dontwarn io.flutter.embedding.**
-ignorewarnings
-keep class * {
    public private *;
}
