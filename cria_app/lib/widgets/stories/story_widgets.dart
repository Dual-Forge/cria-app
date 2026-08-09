import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Progresso de buffering exibido durante o carregamento da mídia do story.
class StoryLoadingIndicator extends StatelessWidget {
  final String message;
  const StoryLoadingIndicator({super.key, this.message = 'Carregando…'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exibe uma [String] de URL como imagem com `BoxFit.cover` e cache.
class StoryImage extends StatelessWidget {
  final String url;
  const StoryImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(color: Colors.black),
      errorWidget: (context, url, error) => const _StoryErrorIcon(),
    );
  }
}

class _StoryErrorIcon extends StatelessWidget {
  const _StoryErrorIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
      ),
    );
  }
}

/// Marcação escura atrás da mídia enquanto ela decodifica.
class StoryPlaceholder extends StatelessWidget {
  const StoryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black);
  }
}

/// Quando a mídia não existe mais (memória excluída) ou é de tipo inválido.
class StoryMediaUnavailable extends StatelessWidget {
  const StoryMediaUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hide_image, color: Colors.white70, size: 56),
            SizedBox(height: 12),
            Text(
              'Mídia indisponível',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradiente sutil para legibilidade do overlay em fotos claras.
class StoryGradientScrim extends StatelessWidget {
  const StoryGradientScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x99000000),
            Colors.transparent,
            Colors.transparent,
            Color(0xCC000000),
          ],
          stops: [0.0, 0.25, 0.6, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// Texto com sombra para legibilidade sobre qualquer fundo de foto.
class StoryShadowText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  const StoryShadowText({
    super.key,
    required this.text,
    this.style = const TextStyle(color: Colors.white, fontSize: 15),
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(
        shadows: const [
          Shadow(
            color: Colors.black87,
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Texto da idade (destaque) da memória.
class StoryAgeText extends StatelessWidget {
  final String text;
  const StoryAgeText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return StoryShadowText(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
    );
  }
}

/// Imagem de capa (avatar) do story — arredondada, com cache.
class StoryAvatar extends StatelessWidget {
  final String url;
  final double size;
  const StoryAvatar({super.key, required this.url, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            Container(color: Colors.grey[800], width: size, height: size),
        placeholder: (context, _) =>
            Container(color: Colors.grey[800], width: size, height: size),
      ),
    );
  }
}