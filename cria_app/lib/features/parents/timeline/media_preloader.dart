/// MediaPreloader
///
/// Estratégia de carregamento otimizado para o visualizador de stories:
/// pré-carrega as imagens com alta prioridade ANTES da próxima story entrar
/// em tela, evitando o "flash" de loading entre uma story e outra.
///
/// Usa o `cached_network_image` (CachedNetworkImageProvider), que combina
/// cache em memória + em disco. O download já decodificado é alimentado no
/// `ImageCache` nativo do Flutter via [precacheImage], de modo que as imagens
/// repetidas (ex.: mesmo avatar em várias telas) são servidas da memória em
/// vez de refeitas da rede.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class MediaPreloader {
  MediaPreloader._();

  /// Pré-carrega as URLs e alimenta o cache de memória do Flutter.
  /// `context` é apenas o ancestral do [precacheImage]; o download não fica
  /// atrelado ao ciclo de vida do widget.
  static Future<void> preload(List<String> urls, BuildContext context) async {
    for (final url in urls) {
      if (url.isEmpty) continue;
      await precacheImage(
        CachedNetworkImageProvider(url),
        context,
        onError: (_, _) {}, // Evita exceções propagando para a UI.
      );
    }
  }

  /// Remove as URLs do cache em memória (e do disco via cached_network_image).
  static Future<void> evict(List<String> urls) async {
    for (final url in urls) {
      if (url.isEmpty) continue;
      await CachedNetworkImageProvider(url).evict();
    }
  }

  /// Pré-carrega em memória as URLs de memórias IMAGEM próximas na lista.
  ///
  /// `focus` indica qual mídia está em tela; pré-carrega as `lookahead`
  /// seguintes e as anteriores (para voltar no story). Vídeos são ignorados
  /// (não faz sentido buscar bytes de vídeo inteiro em memória).
  static Future<void> preloadImagesNear(
    BuildContext context,
    Iterable<String> mediaUrls,
    int focus, {
    int lookahead = 3,
  }) async {
    final urls = <String>[];
    for (final (i, url) in mediaUrls.indexed) {
      if (i == focus) continue;
      final distance = (i - focus).abs();
      if (distance <= lookahead && url.isNotEmpty) urls.add(url);
    }
    if (urls.isNotEmpty) {
      // Avisa a UI mas não lança; a pré-busca roda em segundo plano.
      try {
        await preload(urls, context);
      } catch (_) {
        // Falha de pré-carregamento não deve quebrar a navegação.
      }
    }
  }
}