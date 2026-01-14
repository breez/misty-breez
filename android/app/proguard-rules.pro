#--------------------------------------
# Preserve Flutter Wrapper code
#--------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

#--------------------------------------
# JNA
#--------------------------------------
-keep class com.sun.jna.** { *; }
-keep class * implements com.sun.jna.** { *; }

#--------------------------------------
# To ignore minifyEnabled: true error
# https://github.com/flutter/flutter/issues/19250
# https://github.com/flutter/flutter/issues/37441
#--------------------------------------
-dontwarn io.flutter.embedding.**
-ignorewarnings
-keep class * {
    public private *;
}

#--------------------------------------
# Android App Links & MicroG SafeParcelable
#--------------------------------------
-keep public class * extends org.microg.safeparcel.AutoSafeParcelable {
    @org.microg.safeparcel.SafeParcelable.Field *;
    @org.microg.safeparcel.SafeParceled *;
}

# Keep asInterface method cause it's accessed from SafeParcel
-keepattributes InnerClasses
-keepclassmembers interface * extends android.os.IInterface {
    public static class *;
}
-keep public class * extends android.os.Binder { public static *; }

#--------------------------------------
# breez_sdk_liquid plugin
#--------------------------------------
-keep class com.breez.breez_sdk_liquid.** { *; }
-keep class breez_sdk_liquid.** { *; }
-keepclassmembers class com.breez.breez_sdk_liquid.** { *; }

#--------------------------------------
# image_cropper / UCrop
#--------------------------------------
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

#--------------------------------------
# Core suppressions (Android internals & Java standard library)
#--------------------------------------
-dontwarn dalvik.system.VMStack
-dontwarn java.lang.**
-dontwarn javax.naming.**
-dontwarn java.awt.**
-dontwarn sun.reflect.Reflection

#--------------------------------------
# Optimization
#--------------------------------------
-dontoptimize
