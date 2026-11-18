# ProGuard Keep Rules for flutter_local_notifications and Gson
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
