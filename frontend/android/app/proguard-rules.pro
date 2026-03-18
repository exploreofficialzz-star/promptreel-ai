# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin Coroutines
-keepclassmembernames class kotlinx.** {
   volatile <fields>;
}

# Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# OkHttp (used by Dio indirectly)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Prevent stripping of reflection-accessed classes
-keepattributes *Annotation*, Signature, Exception

# PromptReel app classes
-keep class com.chastechgroup.promptreel.** { *; }

# General Android
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Play Core SplitCompat - FIX for R8 error
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Play Store Split Application - FIX for R8 error
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication
