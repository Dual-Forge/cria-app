import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../features/parents/timeline/memory_event.dart';
import 'story_widgets.dart';

/// Uma página do stories: exibe a mídia (imagem ou vídeo) de uma memória,
/// com seu próprio controle de progresso e zonas de navegação estilo
/// Instagram.
///
/// Navegação:
/// - toque na [leftZoneSize] da tela → [onPrevious];
/// - toque à direita → [onNext];
/// - toque longo (hold) → pausa a barra de progresso E a reprodução do vídeo;
/// - soltar o hold → retoma.
///
/// A barra de progresso é um [AnimationController] criado pelo pai e passado
/// aqui; a duração é ajustada após o vídeo inicializar (para cobrir apenas o
/// trecho de ≤ 1 min selecionado no trimmer).
class StoryPage extends StatefulWidget {
  final MemoryEvent event;
  final AnimationController progress;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  /// Fração da largura (a partir da esquerda) que conta como "voltar".
  final double leftZoneSize;

  const StoryPage({
    super.key,
    required this.event,
    required this.progress,
    required this.onNext,
    required this.onPrevious,
    this.leftZoneSize = 1 / 3,
  });

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  static const Duration _imageDuration = Duration(seconds: 5);

  VideoPlayerController? _video;
  bool _videoReady = false;

  Timer? _navTimer;
  int _pendingZone = 0; // 0 = direita, 1 = esquerda
  bool _pausedByHold = false;

  @override
  void initState() {
    super.initState();
    widget.progress
      ..duration = _imageDuration
      ..addListener(_onTick)
      ..addStatusListener(_onStatus)
      ..forward(from: 0);

    if (widget.event.isVideo) {
      _setupVideo();
    }
  }

  void _onTick() => setState(() {});

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_pausedByHold) {
      widget.onNext();
    }
  }

  Future<void> _setupVideo() async {
    final evt = widget.event;
    final controller = VideoPlayerController.networkUrl(Uri.parse(evt.mediaUrl));
    try {
      await controller.initialize();

      final totalMs = controller.value.duration.inMilliseconds;
      // Trecho guardado no banco ("corte suave") ou vídeo completo.
      final startMs = (evt.videoStartMs ?? 0).clamp(0, totalMs);
      final endMs = (evt.videoEndMs ?? totalMs).clamp(startMs, totalMs);
      final lenMs = endMs - startMs;

      // Sincroniza a barra de progresso com o trecho exibido.
      if (lenMs > 0) {
        widget.progress.duration = Duration(milliseconds: lenMs);
      }

      await controller.seekTo(Duration(milliseconds: startMs));
      await controller.setLooping(true);

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _videoReady = true;
      });

      controller.play();
      widget.progress.forward(from: 0);
    } catch (e) {
      debugPrint('[StoryPage] Falha ao carregar vídeo: $e');
      if (!mounted) return;
      setState(() => _videoReady = true); // Garante que a UI mostre o fallback
    }
  }

  // ── Gestos ──────────────────────────────────────────────────────────────

  void _onTapDown(TapDownDetails d) {
    final width = MediaQuery.of(context).size.width;
    final isLeft = d.globalPosition.dx < width * widget.leftZoneSize;
    _pendingZone = isLeft ? 1 : 0;
    // Atalho: aguarda o release para não navegar durante um hold.
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(milliseconds: 120), _navigateFromTap);
  }

  void _navigateFromTap() {
    _navTimer = null;
    if (_pendingZone == 1) {
      widget.onPrevious();
    } else {
      widget.onNext();
    }
  }

  void _onHoldStart() {
    _navTimer?.cancel();
    _navTimer = null;
    widget.progress.stop();
    _video?.pause();
    _pausedByHold = true;
    setState(() {});
  }

  void _onHoldEnd() {
    if (!_pausedByHold) return;
    _pausedByHold = false;
    if (widget.progress.isDismissed) {
      widget.progress.forward(from: 0);
    } else {
      widget.progress.forward();
    }
    _video?.play();
    setState(() {});
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: (_) => _navTimer = null,
      onLongPressDown: (_) => _onHoldStart(),
      onLongPressEnd: (_) => _onHoldEnd(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildMedia(),
          // Scrim de legibilidade
          const StoryGradientScrim(),
          _buildInfoOverlay(),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.event.isVideo) {
      final controller = _video;
      if (!_videoReady || controller == null || !controller.value.isInitialized) {
        return const StoryMediaUnavailable();
      }
      // Vídeo com proporção preservada, centralizado sobre fundo preto.
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }
    // Imagem com BoxFit.contain (nada esticado/cortado).
    return Container(
      color: Colors.black,
      child: Center(
        child: CachedNetworkImage(imageUrl: widget.event.mediaUrl),
      ),
    );
  }

  Widget _buildInfoOverlay() {
    final evt = widget.event;
    final hasDesc = evt.description.trim().isNotEmpty;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (evt.ageText.trim().isNotEmpty) ...[
            StoryAgeText(text: evt.ageText),
            const SizedBox(height: 6),
          ],
          if (evt.title.trim().isNotEmpty)
            StoryShadowText(text: evt.title),
          if (hasDesc) ...[
            const SizedBox(height: 8),
            StoryShadowText(
              text: evt.description,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    widget.progress
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus);
    _video?.dispose();
    super.dispose();
  }
}