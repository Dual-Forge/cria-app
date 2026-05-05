/// ProfileRepository
///
/// Responsável por todas as queries Supabase do perfil do usuário.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  const ProfileRepository(this._client);

  /// Busca o perfil completo do usuário autenticado.
  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      return await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      debugPrint('[ProfileRepository] Erro ao buscar perfil: $e');
      return null;
    }
  }

  /// Atualiza os dados do perfil do usuário.
  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      await _client.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      debugPrint('[ProfileRepository] Erro ao atualizar perfil: $e');
    }
  }

  /// Stream em tempo real do perfil do usuário.
  Stream<Map<String, dynamic>?> watchProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }
}
