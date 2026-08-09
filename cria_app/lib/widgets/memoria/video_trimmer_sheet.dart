import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_clip_window_picker.dart';

/// Bottom sheet de recorte de vídeo.
///
/// Apresenta o vídeo com preview ao vivo e o [VideoClipWindowPicker] para o
/// usuário arrastar a janela de até 1 minuto. Retorna o intervalo escolhido
/// `(startMs, endMs)` ou `null` se o usuário cancelar.
///
/// Usado apenas quando o vídeo original ultrapassa 1 minuto. Funciona em Web
/// e mobile (o arquivo é lido como bytes; sem re-encode).
Future<(int, int)?> showVideoTrimmerSheet({
  required BuildContext context,
  required String filePath,
}) {
  return showModalBottomSheet<(int, int)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (ctx) => _VideoTrimmerSheet(filePath: filePath),
  );
}

class _VideoTrimmerSheet extends StatefulWidget {
  final String filePath;

  const _VideoTrimmerSheet({required this.filePath});

  @override
  State<_VideoTrimmerSheet> createState() => _VideoTrimmerSheetState();
}

class _VideoTrimmerSheetState extends State<_VideoTrimmerSheet> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  Duration? _totalDuration;

  late int _startMs;
  late int _endMs;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Web: o image_picker expõe um blob: URL como path — reproduzível por
      // um <video> nativo. Mobile: caminho real no sistema de arquivos.
      final controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(widget.filePath))
          : VideoPlayerController.file(io.File(widget.filePath));

      await controller.initialize();
      final dur = controller.value.duration;
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _totalDuration = dur;
        _isInitializing = false;
      });
      await controller.seekTo(Duration.zero);
      await controller.setLooping(true);
      await controller.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitializing = false);
      debugPrint('[Trimmer] Falha ao inicializar vídeo: $e');
    }
  }

  void _onClipChanged((int startMs, int endMs) clip) {
    _startMs = clip.$1;
    _endMs = clip.$2;
  }

  /// Pausa a reprodução e devolve o intervalo selecionado.
  void _confirm() {
    _controller?.pause();
    Navigator.of(context).pop((_startMs, _endMs));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Center(
                child: Text(
                  'Escolha o trecho do vídeo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Arraste as bordas para selecionar até 1 minuto.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 16),

              // Preview
              _buildPreview(),

              const SizedBox(height: 16),

              // Seletor de janela
              if (_totalDuration != null)
                VideoClipWindowPicker(
                  totalDuration: _totalDuration!,
                  onClipChanged: _onClipChanged,
                )
              else
                const SizedBox.shrink(),

              const SizedBox(height: 20),

              // Ações
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitializing ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Usar trecho selecionado',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_isInitializing) {
      return _buildBoxedPlaceholder(
        height: 160,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildBoxedPlaceholder(
        height: 120,
        child: const Center(
          child: Text(
            'Não foi possível carregar o vídeo.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final ratio = controller.value.aspectRatio;

    // Altura máxima do preview, para vídeo retrato (9:16) caber sem estourar.
    // Vídeos paisagem ocupam essa largura naturalmente; retratos ficam
    // centralizados com BoxFit.contain e faixas laterais escuras.
    const previewMaxHeight = 220.0;
    final previewHeight = (MediaQuery.of(context).size.width - 40) / ratio;
    final boundedHeight = previewHeight.clamp(120.0, previewMaxHeight);

    return Container(
      height: boundedHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vídeo com proporção preservada (contain), sem esticar.
          Center(
            child: AspectRatio(
              aspectRatio: ratio,
              child: VideoPlayer(controller),
            ),
          ),
          // Botão play/pause
          GestureDetector(
            onTap: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              setState(() {});
            },
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
    );
  }

  Widget _buildBoxedPlaceholder({
    required double height,
    required Widget child,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
