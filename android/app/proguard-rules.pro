# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-keepclassmembers class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Firebase (Core / Auth / Realtime Database)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep public class com.google.android.gms.ads.identifier.AdvertisingIdClient { *; }
-keep public class com.google.android.gms.ads.identifier.AdvertisingIdClient$Info { *; }
-dontwarn com.google.android.gms.ads.**

# Google Play Billing (in_app_purchase)
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }
-dontwarn com.android.billingclient.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.work.impl.background.systemalarm.RescheduleReceiver
-dontwarn com.dexterous.**

# Play Core (split installs / deferred components) — required since R8 full mode is default
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Syncfusion PDF
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# printing / pdf
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep native-method holders and Parcelables
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable fields
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Gson / reflection-based JSON model classes (if any are added later)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Suppress warnings for missing optional desugar classes
-dontwarn java.lang.invoke.StringConcatFactory
