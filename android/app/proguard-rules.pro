# Google ML Kit text recognition - optional language modules
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# FlutterLlama JNI bridge - inner classes accessed by native code
-keep class net.nativemind.flutter_llama.FlutterLlamaPlugin { *; }
-keep class net.nativemind.flutter_llama.FlutterLlamaPlugin$GenerationResult { *; }
-keep class net.nativemind.flutter_llama.FlutterLlamaPlugin$ModelInfo { *; }

