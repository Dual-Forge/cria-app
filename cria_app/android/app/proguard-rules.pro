# Regras R8/ProGuard para o build release (com.dualforge.cria).
# Manter as classes do Flutter/plugins que usam reflexão.

# Supabase / Kotlinx serialization e suporte a JSON
-dontwarn kotlinx.serialization.**
-keep class kotlinx.coroutines.** { *; }

# Flutter engine usa reflexão; manter entradas padrão do template Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Deferred components do engine (split APKs) não são usados; suprimir avisos
# de classes ausentes do play-core que o R8 não consegue resolver.
-dontwarn com.google.android.play.core.**