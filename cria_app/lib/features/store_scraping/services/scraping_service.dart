/// ScrapingService
///
/// Isola toda a lógica de web scraping da UI.
/// A tela apenas chama scrapeProduct(url) e recebe um ScrapedProduct.
///
/// Atenção: scraping via HTTP direto é desabilitado na Web (CORS).
/// Nesse caso, utilize uma Edge Function Supabase como proxy.
library;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── Modelo ────────────────────────────────────────────────────────────────────

class ScrapedProduct {
  final String title;
  final String imageUrl;
  final double? price;
  final String originalUrl;

  const ScrapedProduct({
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.originalUrl,
  });

  bool get hasPrice => price != null;
  bool get hasImage => imageUrl.isNotEmpty;
}

// ── Serviço ───────────────────────────────────────────────────────────────────

class ScrapingService {
  const ScrapingService();

  /// Tenta extrair título, imagem e preço de uma URL de produto.
  ///
  /// Retorna `null` se:
  /// - Estiver rodando na Web (CORS bloqueado)
  /// - A URL for inválida
  /// - Ocorrer qualquer erro de rede
  Future<ScrapedProduct?> scrapeProduct(String url) async {
    if (kIsWeb) {
      debugPrint('[ScrapingService] Scraping desabilitado na Web (CORS).');
      return null;
    }

    if (url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0 CriaApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final html = response.body;

      final title = _extractMetaContent(html, 'og:title') ??
          _extractMetaContent(html, 'twitter:title') ??
          _extractTitleTag(html) ??
          '';

      final imageUrl = _extractMetaContent(html, 'og:image') ??
          _extractMetaContent(html, 'twitter:image') ??
          '';

      final price = _extractPrice(html);

      return ScrapedProduct(
        title: title.trim(),
        imageUrl: imageUrl.trim(),
        price: price,
        originalUrl: url,
      );
    } catch (e) {
      debugPrint('[ScrapingService] Erro ao fazer scraping de $url: $e');
      return null;
    }
  }

  // ── Extratores Privados ───────────────────────────────────────────────────

  String? _extractMetaContent(String html, String property) {
    final patterns = [
      RegExp('property=["\']$property["\']\\s+content=["\']([^"\']+)["\']',
          caseSensitive: false),
      RegExp('content=["\']([^"\']+)["\']\\s+property=["\']$property["\']',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  String? _extractTitleTag(String html) {
    final match =
        RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
            .firstMatch(html);
    return match?.group(1);
  }

  double? _extractPrice(String html) {
    // Regex para formatos: R$ 1.234,56 | R$1234,56 | 1.234,56
    final pattern = RegExp(
      r'R\$\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?|\d+(?:,\d{2})?)',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(html);
    if (match == null) return null;

    final raw = match
        .group(1)!
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(raw);
  }
}
