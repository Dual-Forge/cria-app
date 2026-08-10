/// AppDependencies — container de injeção de dependência (DI).
///
/// Centraliza o acesso ao client do Supabase e aos repositórios/services.
/// As telas idealmente recebem o client por construtor; quando não recebem,
/// resolvem via [AppDependencies.client], que respeita o override de teste.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cria_app/features/ai_specialist/services/ai_service.dart';
import 'package:cria_app/features/ai_specialist/repositories/chat_repository.dart';
import 'package:cria_app/features/baby/repositories/baby_repository.dart';
import 'package:cria_app/features/parents/repositories/profile_repository.dart';
import 'package:cria_app/features/store_scraping/repositories/item_repository.dart';

class AppDependencies {
  AppDependencies._();

  /// Override opcional usado em testes (mocktail) para injetar um client falso.
  static SupabaseClient? _overrideClient;

  /// Seta o client para testes. Passe `null` para voltar ao singleton real.
  static set overrideClient(SupabaseClient? client) => _overrideClient = client;

  /// Client resolvido: override de teste ou o singleton do Supabase.
  static SupabaseClient get client => _overrideClient ?? Supabase.instance.client;

  // ── Repositórios / services (prontos para injeção em telas) ───────────────

  static BabyRepository get babyRepository => BabyRepository(client);
  static ItemRepository get itemRepository => ItemRepository(client);
  static ProfileRepository get profileRepository => ProfileRepository(client);
  static ChatRepository get chatRepository => ChatRepository(client);
  static AIService get aiService => AIService(client);
}