import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centraliza o acesso a todas as variáveis de ambiente do app.
///
/// Prioridade: dart-define (Vercel/CI) → .env (desenvolvimento local)
class EnvConfig {
  EnvConfig._();

  // ── Supabase ──────────────────────────────────────────────────────────────

  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  // ── Gemini AI ─────────────────────────────────────────────────────────────

  static String get geminiApiKey => _get('GEMINI_API_KEY');

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Retorna verdadeiro se todas as chaves críticas estão configuradas.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      geminiApiKey.isNotEmpty;

  /// Busca a variável: dart-define tem prioridade sobre .env
  static String _get(String key) {
    // 1. Tenta dart-define (injetado via Vercel / CI --dart-define)
    final fromDartDefine = _getFromDartDefine(key);
    if (fromDartDefine.isNotEmpty) return fromDartDefine;

    // 2. Fallback para .env (desenvolvimento local)
    final fromDotenv = dotenv.env[key] ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;

    debugPrint('[EnvConfig] AVISO: Chave "$key" não encontrada em nenhuma fonte.');
    return '';
  }

  static String _getFromDartDefine(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
      case 'GEMINI_API_KEY':
        return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      default:
        return '';
    }
  }
}
