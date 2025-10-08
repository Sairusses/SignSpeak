# Keep annotation processing classes used by AutoValue and JavaPoet
-keep class javax.annotation.processing.** { *; }
-keep class javax.lang.model.** { *; }
-keep class com.google.auto.value.** { *; }
-keep class autovalue.shaded.com.squareup.javapoet.** { *; }

# Keep TensorFlow Lite GPU delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }

# Avoid warnings
-dontwarn javax.annotation.**
-dontwarn javax.lang.model.**
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn javax.tools.Diagnostic$Kind
-dontwarn javax.tools.JavaFileObject