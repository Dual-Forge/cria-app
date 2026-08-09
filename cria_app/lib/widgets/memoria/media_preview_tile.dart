import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Prévia da mídia selecionada no formulário de memória.
///
/// Imagem: [Image.memory] com [BoxFit.cover]. Vídeo: player ao vivo (loop)
/// com AspectRatio calculado e botão play/pause.
class MediaPreviewTile extends StatefulWidget {
  /// Caminho do arquivo selecionado (no Web é um blob: URL do image_picker).
  final String filePath;

  final Uint8List bytes;
  final bool isVideo;

  const MediaPreviewTile({
    super.key,
    required this.filePath,
    required this.bytes,
    required this.isVideo,
  });

  @override
  State<MediaPreviewTile> createState() => _MediaPreviewTileState();
}

class _MediaPreviewTileState extends State<MediaPreviewTile> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      // O caminho pode ser um blob: URL (web), um caminho local (mobile) ou
      // uma URL remota (story existente / vídeo da timeline). Decide a forma
      // de carregamento pelo formato do caminho.
      final isRemote = widget.filePath.startsWith('http');
      final controller = (kIsWeb || isRemote)
          ? VideoPlayerController.networkUrl(Uri.parse(widget.filePath))
          : VideoPlayerController.file(io.File(widget.filePath));
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _videoController = controller);
    } catch (e) {
      debugPrint('[MediaPreviewTile] Falha no vídeo: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Image.memory(
            widget.bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          ),
        ),
      );
    }

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 56),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            GestureDetector(
              onTap: () => setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              }),
              child: Container(
                color: Colors.transparent,
                child: controller.value.isPlaying
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.play_circle_fill,
                        size: 56,
                        color: Colors.white70,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}