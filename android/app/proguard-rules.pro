# App & Flutter rules
-keep class com.example.batikmu.** { *; }

# TensorFlow Lite (on-device inference)
-keep class org.tensorflow.lite.** { *; }
-keepclasseswithmembers class org.tensorflow.lite.** {
    native <methods>;
}
-dontwarn org.tensorflow.lite.gpu.**

# AudioPlayers plugin
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# Flutter plugins & common Android SDK reflection / optional deps
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn io.flutter.plugins.**
