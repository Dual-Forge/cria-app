/// BabyRepository
///
/// Responsável por todas as queries Supabase relacionadas ao bebê e família.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BabyRepository {
  final SupabaseClient _client;

  const BabyRepository(this._client);

  /// Busca os dados da família pelo ID do usuário autenticado.
  Future<Map<String, dynamic>?> fetchFamilyByUserId(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['family_id'] == null) return null;

      return await _client
          .from('families')
          .select()
          .eq('id', profile['family_id'])
          .maybeSingle();
    } catch (e) {
      debugPrint('[BabyRepository] Erro ao buscar família: $e');
      return null;
    }
  }

  /// Atualiza os dados do bebê (nome, sexo, DUM).
  Future<void> updateBabyInfo({
    required String familyId,
    String? babyName,
    String? babyGender,
    DateTime? dumDate,
  }) async {
    final updates = <String, dynamic>{};
    if (babyName != null) updates['baby_name'] = babyName;
    if (babyGender != null) updates['baby_gender'] = babyGender;
    if (dumDate != null) updates['dum_date'] = dumDate.toIso8601String();

    if (updates.isEmpty) return;

    try {
      await _client.from('families').update(updates).eq('id', familyId);
    } catch (e) {
      debugPrint('[BabyRepository] Erro ao atualizar dados do bebê: $e');
    }
  }

  /// Stream em tempo real dos dados da família.
  Stream<Map<String, dynamic>?> watchFamily(String familyId) {
    return _client
        .from('families')
        .stream(primaryKey: ['id'])
        .eq('id', familyId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }
}
