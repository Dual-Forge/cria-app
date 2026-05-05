/// ItemRepository
///
/// Responsável por todas as queries Supabase para itens de enxoval
/// e contribuições de presentes.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemRepository {
  final SupabaseClient _client;

  const ItemRepository(this._client);

  /// Busca todos os itens de uma família, opcionalmente filtrados por categoria.
  Future<List<Map<String, dynamic>>> fetchItems({
    required String familyId,
    String? category,
    String? ageRange,
  }) async {
    try {
      var query = _client.from('items').select().eq('family_id', familyId);

      if (category != null) query = query.eq('category', category);
      if (ageRange != null && ageRange != 'Todos') {
        query = query.eq('age_range', ageRange);
      }

      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[ItemRepository] Erro ao buscar itens: $e');
      return [];
    }
  }

  /// Busca apenas os itens marcados como presentes (vitrine pública).
  Future<List<Map<String, dynamic>>> fetchGiftItems(String familyId) async {
    try {
      final data = await _client
          .from('items')
          .select()
          .eq('family_id', familyId)
          .eq('is_gift', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[ItemRepository] Erro ao buscar presentes: $e');
      return [];
    }
  }

  /// Atualiza o status de um item.
  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _client.from('items').update(updates).eq('id', itemId);
    } catch (e) {
      debugPrint('[ItemRepository] Erro ao atualizar item: $e');
    }
  }

  /// Busca as contribuições de presentes de uma família.
  Future<List<Map<String, dynamic>>> fetchGiftContributions(
      String familyId) async {
    try {
      final data = await _client
          .from('gift_contributions')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[ItemRepository] Erro ao buscar contribuições: $e');
      return [];
    }
  }
}
