# ========================================
# ✅ 1. Gson & TypeToken Fix (الحل الجذري)
# ========================================
# هاد السطر هو الأهم: كيقول لـ R8 يخلي التوقيعات (Generics)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# حماية مكتبة Gson بالكامل
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# ========================================
# ✅ 2. Flutter Local Notifications Data Models
# ========================================
# حماية البيانات اللي كتسجلها المكتبة باش Gson يقدر يقراها
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ========================================
# ✅ 3. WorkManager & Android Core
# ========================================
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-keep class androidx.startup.** { *; }

# ========================================
# ✅ 4. Shared Preferences & Location
# ========================================
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# ========================================
# ✅ 5. Firebase & Google Services
# ========================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ========================================
# ✅ 6. Google AI & Play Core
# ========================================
-keep class com.google.ai.** { *; }
-keep class com.google.generativeai.** { *; }
-dontwarn com.google.ai.**
-dontwarn com.google.android.play.core.**

# ========================================
# ✅ 7. Ignore Samsung/Bloatware Errors
# ========================================
-dontwarn com.digitalturbine.**
-dontwarn com.logia.**

# ========================================
# ✅ 8. Flutter Core & Standard Rules
# ========================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}