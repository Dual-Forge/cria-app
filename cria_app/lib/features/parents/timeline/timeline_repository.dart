/// TimelineRepository
///
/// Centraliza TODAS as operações Supabase relacionadas à linha do tempo do
/// bebê (tabela `baby_timeline` e bucket de storage). A UI nunca toca no
/// Supabase diretamente para memórias — apenas neste repositório.
///
/// Preparado para RBAC: os métodos de criação/edição/exclusão são os pontos
/// únicos onde o futuro "Modo Convidado" deve ser bloqueado. A UI isola os
/// botões de ação por [TimelineAccessScope], e o repositório é a segunda
/// barreira, caso um convidado dispare uma requisição.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'memory_event.dart';

class TimelineRepository {
  final SupabaseClient _client;
  final String? familyId;

  const TimelineRepository(this._client, {this.familyId});

  /// Busca o nome do bebê da família.
  Future<String?> fetchBabyName(String familyId) async {
    try {
      final family = await _client
          .from('families')
          .select('baby_name')
          .eq('id', familyId)
          .maybeSingle();
      return family?['baby_name']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Lista as memórias ordenadas da mais recente para a mais antiga (a UI
  /// inverte para exibir cronologicamente nos stories).
  Future<List<MemoryEvent>> fetchTimeline() async {
    final data = await _client
        .from('baby_timeline')
        .select()
        .eq('family_id', familyId!)
        .order('date', ascending: false);
    return data.map((row) => MemoryEvent.fromMap(row)).toList();
  }

  /// Cria uma nova memória. O arquivo é enviado para o storage e a URL
  /// pública é persistida na linha da tabela.
  ///
  /// `ext` e `contentType` permitem preservar a extensão real do arquivo
  /// original (jpg/png/heic/mp4/mov). Para vídeos, `clipStartMs`/`clipEndMs`
  /// definem o trecho de até 1 minuto a ser reproduzido ("corte suave").
  Future<void> addMemory({
    required Uint8List mediaBytes,
    required String ext,
    required String contentType,
    required String title,
    required String description,
    required String ageText,
    required DateTime date,
    required bool isVideo,
    int? clipStartMs,
    int? clipEndMs,
  }) async {
    final fileName =
        '${familyId!}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          mediaBytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    final mediaUrl = _client.storage.from('avatars').getPublicUrl(fileName);

    await _client.from('baby_timeline').insert({
      'family_id': familyId,
      'image_url': mediaUrl,
      'media_type': isVideo ? 'video' : 'image',
      'title': title,
      'description': description,
      'age_text': ageText,
      'date': date.toIso8601String(),
      'video_start_ms': isVideo ? clipStartMs : null,
      'video_end_ms': isVideo ? clipEndMs : null,
    });
  }

  /// Atualiza os metadados de uma memória (título, descrição, idade e data).
  Future<void> updateMemory({
    required String id,
    required String title,
    required String description,
    required String ageText,
    required DateTime date,
  }) async {
    await _client
        .from('baby_timeline')
        .update({
          'title': title,
          'description': description,
          'age_text': ageText,
          'date': date.toIso8601String(),
        })
        .eq('id', id);
  }

  /// Define a foto do evento como foto de perfil do bebê.
  Future<void> setAsProfilePhoto(String mediaUrl) async {
    await _client
        .from('families')
        .update({'baby_photo_url': mediaUrl})
        .eq('id', familyId!);
  }

  /// Remove uma memória do banco e, se possível, do storage.
  ///
  /// Se a memória deletada era a foto de perfil, limpa o campo na família.
  Future<void> deleteMemory(MemoryEvent event) async {
    // Se a foto deletada for a foto de perfil, definir como nulo
    final profile = await _client
        .from('families')
        .select('baby_photo_url')
        .eq('id', familyId!)
        .maybeSingle();
    if (profile != null && profile['baby_photo_url'] == event.mediaUrl) {
      await _client
          .from('families')
          .update({'baby_photo_url': null})
          .eq('id', familyId!);
    }

    await _client.from('baby_timeline').delete().eq('id', event.id);

    // Tenta deletar do storage se o bucket for 'avatars' (ignora falha)
    try {
      final uri = Uri.parse(event.mediaUrl);
      final segments = uri.pathSegments;
      final idx = segments.indexOf('avatars');
      if (idx != -1 && idx < segments.length - 1) {
        await _client.storage
            .from('avatars')
            .remove([segments.sublist(idx + 1).join('/')]);
      }
    } catch (_) {}
  }
}