# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# For native libraries, we don't want to obfuscate them
-keep class com.kiblaapp.islamic.** { *; }

# Keep the library classes from the specific packages we use
-keep class com.google.android.gms.** { *; }
-keep class androidx.** { *; }

# Specific rules for Flutter plugins
-keep class io.flutter.plugins.audioplayers.** { *; }
-keep class io.flutter.plugins.localnotifications.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep classes with @Keep annotation
-keep class androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}

# Rules for Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Rules for Flutter Compass
-keep class com.hemanthraj.fluttercompass.** { *; }
