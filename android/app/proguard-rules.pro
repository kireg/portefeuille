# Flutter Secure Storage - Tink/Crypto dependencies
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn com.google.errorprone.annotations.InlineMe
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
-dontwarn javax.annotation.concurrent.ThreadSafe

# Google API Client
-dontwarn com.google.api.client.http.**
-dontwarn com.google.api.client.http.javanet.**

# Joda Time
-dontwarn org.joda.time.**

# Keep Tink classes
-keep class com.google.crypto.tink.** { *; }

# Local Auth & Biometric
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
