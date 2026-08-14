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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Retorna verdadeiro se as variáveis críticas estão configuradas.
  ///
  /// A chave da IA (Groq) NÃO entra aqui: vive como variável de ambiente da
  /// Edge Function `ai-proxy`, nunca no cliente (SEG-05 / IA-03).
  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Busca a variável: dart-define tem prioridade sobre .env
  static String _get(String key) {
    // 1. Tenta dart-define (injetado via Vercel / CI --dart-define)
    final fromDartDefine =
        _getFromDartDefine(key).trim().replaceAll('"', '').replaceAll("'", '');
    if (fromDartDefine.isNotEmpty) return fromDartDefine;

    // 2. Fallback para .env (desenvolvimento local)
    // Só acessa dotenv.env se foi inicializado (nunca em web)
    String fromDotenv = '';
    try {
      fromDotenv =
          dotenv.env[key]?.trim().replaceAll('"', '').replaceAll("'", '') ?? '';
    } catch (_) {
      // dotenv não foi inicializado, ignora
    }
    if (fromDotenv.isNotEmpty) return fromDotenv;

    debugPrint('[EnvConfig] AVISO: Chave "$key" não encontrada em nenhuma fonte.');
    return '';
  }

  static String _getFromDartDefine(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: '',
        );
      default:
        return '';
    }
  }
}
