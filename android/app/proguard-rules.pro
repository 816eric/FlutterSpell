# Keep ML Kit text recognizer options
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep ML Kit Builder classes
-keep class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder { *; }
-keep class com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder { *; }
-keep class com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder { *; }
-keep class com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder { *; }
