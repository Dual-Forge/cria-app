import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import 'package:cria_app/features/parents/timeline/memory_event.dart';
import 'package:cria_app/features/parents/timeline/timeline_access.dart';
import 'package:cria_app/features/parents/timeline/timeline_repository.dart';
import 'package:cria_app/features/parents/timeline/media_preloader.dart';
import 'package:cria_app/widgets/app_background.dart';
import 'package:cria_app/widgets/memoria/media_preview_tile.dart';
import 'package:cria_app/widgets/memoria/memory_form_sheet.dart';
import 'package:cria_app/widgets/memoria/video_trimmer_sheet.dart';
import 'package:cria_app/widgets/stories/stories_screen.dart';
import 'package:cria_app/widgets/timeline/memory_card.dart';
import 'package:cria_app/widgets/timeline/timeline_actions_bar.dart';

/// Linha do Tempo do bebê.
///
/// Tela fina de apresentação: delega o acesso a dados a [TimelineRepository],
/// o estado de permissão a [TimelineAccessScope] e a construção visual aos
/// widgets reutilizáveis (card, stories, formulário, barra de ações).
///
/// Preparado para o futuro "Modo Convidado": os CRUDs e botões de ação são
/// isolados e ocultos quando `scope.canManage` for `false`.
class TimelineScreen extends StatefulWidget {
  final Color currentTheme;
  final String? familyId;

  const TimelineScreen({super.key, required this.currentTheme, this.familyId});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late final TimelineRepository _repo;
  late final TimelineAccessScope _scope;

  bool _isLoading = true;
  String? _babyName = 'Bebê';
  List<MemoryEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _repo = TimelineRepository(Supabase.instance.client, familyId: widget.familyId);
    _scope = TimelineAccess.of();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.familyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final name = await _repo.fetchBabyName(widget.familyId!);
      final events = await _repo.fetchTimeline();
      if (!mounted) return;

      setState(() {
        if (name != null) _babyName = name;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Timeline] Erro ao carregar dados: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ── Seleção de mídia ─────────────────────────────────────────────────────

  Future<void> _addMedia() async {
    if (!_scope.canManage) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.deepPurple),
                title: const Text('Adicionar Foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.deepPurple),
                title: const Text('Adicionar Vídeo'),
                subtitle: const Text('Máximo de 1 minuto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(bool isVideo) async {
    final picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);

    debugPrint('[Timeline] Pedindo seleção de ${isVideo ? 'vídeo' : 'foto'}…');
    final XFile? pickedFile;
    try {
      pickedFile = isVideo
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      debugPrint('[Timeline] Erro ao abrir galeria: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível acessar a galeria.')),
      );
      return;
    }

    if (pickedFile == null || !mounted) return;
    debugPrint('[Timeline] Arquivo selecionado: ${pickedFile.name}');

    // Duração para vídeos: calcula o trecho de até 1 minuto.
    int? clipStartMs;
    int? clipEndMs;
    Uint8List? clipBytes; // Bytes do vídeo (lidos p/ o trimmer, reusados no upload)
    if (isVideo) {
      final duration = await _readVideoDuration(pickedFile.path);
      if (duration == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível ler o vídeo.')),
        );
        return;
      }
      debugPrint('[Timeline] Duração do vídeo: ${duration.inSeconds}s');
      if (duration.inSeconds > 60 && mounted) {
        // Abre o trimmer e cancela o fluxo se o usuário não escolher trecho.
        debugPrint('[Timeline] Lendo bytes para o trimmer…');
        try {
          clipBytes = await pickedFile
              .readAsBytes()
              .timeout(const Duration(seconds: 30));
        } catch (e) {
          debugPrint('[Timeline] Erro ao ler bytes do vídeo: $e');
          messenger.showSnackBar(
            const SnackBar(content: Text('Não foi possível ler o vídeo.')),
          );
          return;
        }
        if (!mounted) return;
        final clip = await showVideoTrimmerSheet(
          context: context,
          filePath: pickedFile.path,
          bytes: clipBytes,
        );
        if (clip == null) return;
        clipStartMs = clip.$1;
        clipEndMs = clip.$2;
        debugPrint('[Timeline] Trecho escolhido: $clipStartMs–$clipEndMs ms');
      }
    }

    debugPrint('[Timeline] Preparando bytes do arquivo…');
    // Reutiliza os bytes já lidos no trimmer (vídeo longo) para evitar ler 2x.
    final Uint8List bytes = clipBytes ??
        (await _readFileBytes(pickedFile, messenger));
    if (bytes.isEmpty) return;
    debugPrint('[Timeline] Bytes prontos: ${bytes.length}');

    if (!mounted) return;

    // Preserva a extensão real do arquivo (mobile) ou do nome (web).
    final ext = _guessExtension(pickedFile.name, isVideo);

    final media = AddMemoryMedia(
      bytes: bytes,
      filePath: pickedFile.path,
      ext: ext,
      contentType: isVideo ? 'video/$ext' : 'image/$ext',
      isVideo: isVideo,
      clipStartMs: clipStartMs,
      clipEndMs: clipEndMs,
    );

    await showAddMemorySheet(
      context: context,
      media: media,
      onSubmit: _uploadMemory,
    );
  }

  /// Lê os bytes de um arquivo selecionado com timeout e feedback amigável.
  Future<Uint8List> _readFileBytes(
    XFile file,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      return await file.readAsBytes().timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('[Timeline] Erro ao ler bytes: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível ler o arquivo. Tente outro.'),
        ),
      );
      return Uint8List(0);
    }
  }

  /// Lê a duração de um vídeo com proteção contra travamento (timeout).
  Future<Duration?> _readVideoDuration(String path) async {
    VideoPlayerController? controller;
    try {
      debugPrint('[Timeline] Iniciando leitura de duração…');
      controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(path))
          : VideoPlayerController.file(io.File(path));
      // initialize pode pendurar em vídeos pesados; aplica timeout.
      await controller
          .initialize()
          .timeout(const Duration(seconds: 15));
      final dur = controller.value.duration;
      debugPrint('[Timeline] Duração lida: $dur');
      return dur;
    } catch (e) {
      debugPrint('[Timeline] Erro ao ler duração do vídeo: $e');
      return null;
    } finally {
      // Sempre libera o controlador, mesmo em indisponibilidade.
      try {
        await controller?.dispose();
      } catch (_) {}
    }
  }

  String _guessExtension(String fileName, bool isVideo) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (ext.isEmpty) return isVideo ? 'mp4' : 'jpg';
    if (isVideo) return ext == 'mov' || ext == 'mp4' || ext == 'webm' ? ext : 'mp4';
    return ext;
  }

  Future<void> _uploadMemory(MemoryFormResult result) async {
    // Guarda referências antes do await (evita use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);

    debugPrint('[Timeline] Upload iniciado (vídeo=${result.isVideo}, '
        'bytes=${result.bytes.length}, ext=${result.ext})');

    setState(() => _isLoading = true);
    try {
      await _repo.addMemory(
        mediaBytes: result.bytes,
        ext: result.ext,
        contentType: result.contentType,
        title: result.title,
        description: result.description,
        ageText: result.ageText,
        date: result.date,
        isVideo: result.isVideo,
        clipStartMs: result.clipStartMs,
        clipEndMs: result.clipEndMs,
      );
      debugPrint('[Timeline] Upload concluído. Recarregando dados…');

      await _loadData();
      debugPrint('[Timeline] Timeline recarregada.');
    } catch (e) {
      debugPrint('[Timeline] Erro ao fazer upload: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Erro ao salvar memória. Tente novamente.')),
      );
    } finally {
      // Garante que a tela nunca fique travada no loading, mesmo em falha.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Ações do card (editar/excluir/perfil) ────────────────────────────────

  void _editMemory(MemoryEvent event) {
    showEditMemorySheet(
      context: context,
      event: event,
      onSubmit: ({required title, required description, required ageText, required date}) async {
        setState(() => _isLoading = true);
        try {
          await _repo.updateMemory(
            id: event.id,
            title: title,
            description: description,
            ageText: ageText,
            date: date,
          );
          await _loadData();
        } catch (e) {
          debugPrint('[Timeline] Erro ao atualizar memória: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao atualizar memória.')),
          );
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _deleteMemory(MemoryEvent event) async {
    setState(() => _isLoading = true);
    try {
      await _repo.deleteMemory(event);
      // Limpa do cache para não exibir cliente antigo.
      MediaPreloader.evict([event.mediaUrl]);
      await _loadData();
    } catch (e) {
      debugPrint('[Timeline] Erro ao apagar memória: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao apagar memória.')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete(MemoryEvent event) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.sentiment_dissatisfied, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Apagar Lembrança?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900),
                ),
              ),
            ],
          ),
          content: Text(
            'Tem certeza que deseja apagar essa lembrança de $_babyName? Essa ação não pode ser desfeita.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteMemory(event);
              },
              child: const Text('Apagar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setAsProfilePhoto(MemoryEvent event) async {
    try {
      await _repo.setAsProfilePhoto(event.mediaUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil do bebê atualizada!')),
      );
    } catch (e) {
      debugPrint('[Timeline] Erro ao atualizar foto de perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar foto de perfil.')),
      );
    }
  }

  // ── Stories / vídeo ──────────────────────────────────────────────────────

  void _openStories() {
    if (_events.isEmpty) return;
    // Inverte para ordem cronológica (mais antigo primeiro).
    final storiesList = _events.reversed.toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoriesScreen(events: storiesList),
      ),
    );
  }

  void _onAvatarTap(MemoryEvent event) {
    if (!event.isVideo) return;
    // Vídeo curto: reproduz ao vivo.
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: MediaPreviewTile(
            filePath: event.mediaUrl,
            bytes: Uint8List(0),
            isVideo: true,
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GlobalBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Linha do Tempo de $_babyName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF2D3142),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  if (_events.isEmpty)
                    const Center(
                      child: Text(
                        'Nenhuma foto adicionada ainda.\nComece a construir a timeline!',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    _buildTimelineList(),

                  // Barra de ações fixa no rodapé
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TimelineActionsBar(
                      scope: _scope,
                      onAddMemory: _addMedia,
                      onViewStories: _openStories,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTimelineList() {
    final dashedColor = widget.currentTheme.withValues(alpha: 0.35);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // Linha tracejada roxa pálida (atrás dos avatares)
          Positioned(
            left: 40,
            top: 0,
            bottom: 120,
            child: CustomPaint(
              painter: DashedLinePainter(color: dashedColor),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 140),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              final dateObj = event.date;
              final formattedDate =
                  DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(dateObj);
              return TimelineMemoryCard(
                event: event,
                scope: _scope,
                ageLabel: event.ageText.isEmpty ? 'Recém-nascido' : event.ageText,
                formattedDate: formattedDate,
                onAvatarTap: () => _onAvatarTap(event),
                onEdit: () => _editMemory(event),
                onDelete: () => _confirmDelete(event),
                onSetAsProfile: () => _setAsProfilePhoto(event),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Desenha a linha tracejada atrás dos avatares.
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 6, dashSpace = 6, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) => oldDelegate.color != color;
}