import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/parents/timeline/memory_event.dart';
import '../../features/parents/timeline/media_preloader.dart';
import 'story_page.dart';
import 'story_widgets.dart';

/// Tela de visualização estilo Instagram (stories) da linha do tempo.
///
/// - Navegação por toque (esquerda volta / direita avança), uma página por
///   memória, progresso por página.
/// - Toque longo pausa a barra e a reprodução.
/// - Pré-carrega imagens próximas (cache em memória/disco) para eliminar o
///   atraso de carregamento entre stories.
/// - Ordem cronológica (evento mais antigo primeiro).
class StoriesScreen extends StatefulWidget {
  final List<MemoryEvent> events;

  const StoriesScreen({super.key, required this.events});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _index;
  late final List<AnimationController> _progressControllers;
  late final List<bool> _visited;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _index = 0;
    _progressControllers = List.generate(
      widget.events.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      ),
    );
    _visited = List.filled(widget.events.length, false);
    _visited[0] = true;
    _startCurrent();
    _preloadNear();
  }

  void _startCurrent() => _progressControllers[_index].forward(from: 0);

  void _preloadNear() {
    // Pré-busca em segundo plano; não bloqueia a rolagem.
    MediaPreloader.preloadImagesNear(
      context,
      widget.events.where((e) => e.isImage).map((e) => e.mediaUrl),
      _index,
    ).ignore();
  }

  void _goNext() {
    if (_index < widget.events.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    if (_index > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _visited[index] = true;
    _startCurrent();
    _preloadNear();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _progressControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Páginas
            PageView.builder(
              controller: _pageController,
              itemCount: widget.events.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) {
                return StoryPage(
                  event: widget.events[i],
                  progress: _progressControllers[i],
                  onNext: _goNext,
                  onPrevious: _goPrev,
                );
              },
            ),

            // Overlay superior: barras + cabeçalho
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: _buildTopOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    final event = widget.events[_index];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barras de progresso
        Row(
          children: List.generate(widget.events.length, (i) {
            final value = i < _index
                ? 1.0
                : (i == _index
                      ? _progressControllers[i].value
                      : (_visited[i] ? 1.0 : 0.0));
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Cabeçalho: avatar/badge + título + data + fechar
        Row(
          children: [
            if (event.isVideo)
              _VideoBadge()
            else
              StoryAvatar(url: event.mediaUrl, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoryShadowText(
                    text: event.title.isEmpty ? 'Memória' : event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  StoryShadowText(
                    text: DateFormat('dd/MM/yyyy').format(event.date),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.videocam, color: Colors.white, size: 18),
    );
  }
}