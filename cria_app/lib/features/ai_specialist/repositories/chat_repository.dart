/// ChatRepository
///
/// Responsável pela persistência de mensagens de chat no Supabase.
/// Separação de responsabilidade: GeminiService foca em IA,
/// ChatRepository foca em armazenamento.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _client;

  const ChatRepository(this._client);

  /// Salva uma mensagem de chat no Supabase (tabela `chat_messages`).
  Future<void> saveMessage({
    required String content,
    required String role, // 'user' | 'model'
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final familyId = await _fetchFamilyId(user.id);

      await _client.from('chat_messages').insert({
        'user_id': user.id,
        'family_id': familyId,
        'role': role,
        'content': content,
      });
    } catch (e) {
      debugPrint('[ChatRepository] Erro ao salvar mensagem: $e');
    }
  }

  /// Busca o histórico de mensagens de chat da família.
  Future<List<Map<String, dynamic>>> fetchHistory({int limit = 50}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final data = await _client
          .from('chat_messages')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[ChatRepository] Erro ao buscar histórico: $e');
      return [];
    }
  }

  // ── Privados ──────────────────────────────────────────────────────────────

  Future<String?> _fetchFamilyId(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      return profile?['family_id'] as String?;
    } catch (e) {
      debugPrint('[ChatRepository] Erro ao buscar family_id: $e');
      return null;
    }
  }
}
