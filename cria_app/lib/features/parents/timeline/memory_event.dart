/// Modelo de domínio para uma memória da linha do tempo do bebê.
///
/// Representa uma linha da tabela `baby_timeline`. Mantém apenas os campos
/// usados pela UI; o acesso ao banco fica centralizado em `TimelineRepository`.
library;

/// Tipos de mídia suportados por uma memória.
enum MemoryMediaType { image, video }

extension MemoryMediaTypeX on MemoryMediaType {
  String get dbValue => switch (this) {
    MemoryMediaType.image => 'image',
    MemoryMediaType.video => 'video',
  };
}

/// Uma memória publicada na linha do tempo.
class MemoryEvent {
  final String id;
  final String familyId;
  final String mediaUrl;
  final MemoryMediaType mediaType;
  final String title;
  final String description;
  final String ageText;
  final DateTime date;

  /// Início do trecho exibido (ms) de vídeos cortados ("corte suave").
  /// `null` para imagens e vídeos reproduzidos por completo.
  final int? videoStartMs;

  /// Fim do trecho exibido (ms) de vídeos cortados.
  /// `null` para imagens e vídeos reproduzidos por completo.
  final int? videoEndMs;

  const MemoryEvent({
    required this.id,
    required this.familyId,
    required this.mediaUrl,
    required this.mediaType,
    required this.title,
    required this.description,
    required this.ageText,
    required this.date,
    this.videoStartMs,
    this.videoEndMs,
  });

  factory MemoryEvent.fromMap(Map<String, dynamic> map) {
    final vStart = map['video_start_ms'];
    final vEnd = map['video_end_ms'];
    return MemoryEvent(
      id: map['id'].toString(),
      familyId: map['family_id'].toString(),
      mediaUrl: map['image_url'].toString(),
      mediaType: map['media_type'] == 'video'
          ? MemoryMediaType.video
          : MemoryMediaType.image,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      ageText: map['age_text']?.toString() ?? '',
      date: DateTime.parse(map['date'].toString()),
      videoStartMs: vStart == null ? null : (vStart as num).toInt(),
      videoEndMs: vEnd == null ? null : (vEnd as num).toInt(),
    );
  }

  /// Duração exibida (em ms) quando a memória é um vídeo com trecho cortado.
  ///
  /// Retorna `null` quando não há um intervalo definido (vídeo completo).
  int? get displayDurationMs {
    if (videoStartMs == null || videoEndMs == null) return null;
    final start = videoStartMs!;
    final end = videoEndMs!;
    return (end > start) ? end - start : null;
  }

  bool get isVideo => mediaType == MemoryMediaType.video;
  bool get isImage => mediaType == MemoryMediaType.image;
}