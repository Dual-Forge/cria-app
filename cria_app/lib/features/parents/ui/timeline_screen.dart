import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:cria_app/widgets/app_background.dart';

class TimelineScreen extends StatefulWidget {
  final Color currentTheme;
  final String? familyId;

  const TimelineScreen({super.key, required this.currentTheme, this.familyId});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _babyName = "Bebê";
  List<Map<String, dynamic>> _timelineEvents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.familyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Carregar nome do bebê
      final familyData = await _supabase
          .from('families')
          .select('baby_name')
          .eq('id', widget.familyId!)
          .maybeSingle();

      if (familyData != null && familyData['baby_name'] != null) {
        _babyName = familyData['baby_name'];
      }

      // Carregar eventos da timeline ordenados por data decrescente
      final timelineData = await _supabase
          .from('baby_timeline')
          .select()
          .eq('family_id', widget.familyId!)
          .order('date', ascending: false);

      setState(() {
        _timelineEvents = List<Map<String, dynamic>>.from(timelineData);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMedia() async {
    showModalBottomSheet(
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
                title: const Text("Adicionar Foto"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.deepPurple),
                title: const Text("Adicionar Vídeo"),
                subtitle: const Text("Máximo de 1 minuto"),
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
    final pickedFile = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || !mounted) return;

    if (isVideo) {
      VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(pickedFile.path));
      } else {
        controller = VideoPlayerController.file(io.File(pickedFile.path));
      }
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();

      if (duration.inSeconds > 60) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O vídeo deve ter no máximo 1 minuto de duração.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    final bytes = await pickedFile.readAsBytes();
    _showAddMediaModal(pickedFile, bytes, isVideo);
  }

  void _showAddMediaModal(XFile file, Uint8List mediaBytes, bool isVideo) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final ageController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Nova Memória",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isVideo)
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white70,
                            size: 64,
                          ),
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          mediaBytes,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ageController,
                      decoration: InputDecoration(
                        labelText: "Idade (ex: 3 Meses)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Título",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Descrição (O que aconteceu?)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        "Data: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() => selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (ageController.text.isEmpty ||
                              titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Preencha a idade e o título!'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _uploadMemory(
                            file,
                            mediaBytes,
                            titleController.text,
                            descController.text,
                            ageController.text,
                            selectedDate,
                            isVideo,
                          );
                        },
                        child: const Text(
                          "Salvar Memória",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _uploadMemory(
    XFile file,
    Uint8List mediaBytes,
    String title,
    String desc,
    String ageText,
    DateTime date,
    bool isVideo,
  ) async {
    setState(() => _isLoading = true);
    try {
      final extension = isVideo ? 'mp4' : 'jpg';
      final contentType = isVideo ? 'video/mp4' : 'image/jpeg';
      final fileName =
          '${widget.familyId}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            mediaBytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final mediaUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // 2. Inserir no banco
      await _supabase.from('baby_timeline').insert({
        'family_id': widget.familyId,
        'image_url': mediaUrl,
        'media_type': isVideo ? 'video' : 'image',
        'title': title,
        'description': desc,
        'age_text': ageText,
        'date': date.toIso8601String(),
      });

      // Recarregar dados
      await _loadData();
    } catch (e) {
      debugPrint("Erro ao fazer upload: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar memória. Tente novamente.'),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMemory(
    String id,
    String title,
    String desc,
    String ageText,
    DateTime date,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('baby_timeline')
          .update({
            'title': title,
            'description': desc,
            'age_text': ageText,
            'date': date.toIso8601String(),
          })
          .eq('id', id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar memória.')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTimelineEvent(Map<String, dynamic> event) async {
    setState(() => _isLoading = true);
    try {
      final String id = event['id'];
      final String imageUrl = event['image_url'];

      // Se a foto deletada for a foto de perfil, definir como nulo
      final profileResponse = await _supabase
          .from('families')
          .select('baby_photo_url')
          .eq('id', widget.familyId!)
          .maybeSingle();
      if (profileResponse != null &&
          profileResponse['baby_photo_url'] == imageUrl) {
        await _supabase
            .from('families')
            .update({'baby_photo_url': null})
            .eq('id', widget.familyId!);
      }

      await _supabase.from('baby_timeline').delete().eq('id', id);

      // Tentar deletar do storage se o bucket for 'avatars' (ignorar erro se falhar)
      try {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final idx = pathSegments.indexOf('avatars');
        if (idx != -1 && idx < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(idx + 1).join('/');
          await _supabase.storage.from('avatars').remove([filePath]);
        }
      } catch (_) {}

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao apagar memória.')));
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.sentiment_dissatisfied, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Apagar Lembrança?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Tem certeza que deseja apagar essa lembrança de ${_babyName}? Essa ação não pode ser desfeita.",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteTimelineEvent(event);
              },
              child: const Text(
                "Apagar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editTimelineEvent(Map<String, dynamic> event) {
    final titleController = TextEditingController(text: event['title']);
    final descController = TextEditingController(text: event['description']);
    final ageController = TextEditingController(text: event['age_text']);
    DateTime selectedDate = DateTime.parse(event['date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Editar Lembrança",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Imagem atual - desativada para edição
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: event['media_type'] == 'video'
                            ? Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: Icon(Icons.videocam, color: Colors.white, size: 40),
                                ),
                              )
                            : Image.network(
                                event['image_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: ageController,
                      decoration: InputDecoration(
                        labelText: "Idade (ex: 2 meses)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Título (ex: Primeiro Sorriso)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Descrição (opcional)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        "Data: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() => selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (ageController.text.isEmpty ||
                              titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Preencha a idade e o título!'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _updateMemory(
                            event['id'],
                            titleController.text,
                            descController.text,
                            ageController.text,
                            selectedDate,
                          );
                        },
                        child: const Text(
                          "Salvar Alterações",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _setAsProfilePhoto(String imageUrl) async {
    try {
      await _supabase
          .from('families')
          .update({'baby_photo_url': imageUrl})
          .eq('id', widget.familyId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil do bebê atualizada!')),
      );
    } catch (e) {
      debugPrint('Erro ao atualizar foto de perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar foto de perfil.')),
      );
    }
  }

  void _openStories() {
    if (_timelineEvents.isEmpty) return;

    // Inverter para ordem cronologica (mais antigo primeiro)
    final storiesList = _timelineEvents.reversed.toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoriesScreen(events: storiesList),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Linha do Tempo de $_babyName",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF2D3142),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false, // Mantendo padrao de abas
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  if (_timelineEvents.isEmpty)
                    const Center(
                      child: Text(
                        "Nenhuma foto adicionada ainda.\nComece a construir a timeline!",
                      ),
                    )
                  else
                    // Linha tracejada e lista
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        children: [
                          // Linha tracejada roxa pálida (posicionada atras dos avatares)
                          Positioned(
                            left: 40, // Metade do tamanho do avatar (80/2)
                            top: 0,
                            bottom: 120, // Espaço para os botoes fixos
                            child: CustomPaint(
                              painter: DashedLinePainter(
                                color: Colors.deepPurple.shade200,
                              ),
                            ),
                          ),

                          // Lista de cards
                          ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 16,
                              bottom: 140,
                            ),
                            itemCount: _timelineEvents.length,
                            itemBuilder: (context, index) {
                              final event = _timelineEvents[index];
                              final dateObj = DateTime.parse(event['date']);
                              final formattedDate = DateFormat(
                                "d 'de' MMMM 'de' yyyy",
                                "pt_BR",
                              ).format(dateObj);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.grey.shade200,
                                          child: GestureDetector(
                                            onTap: () {
                                              if (event['media_type'] == 'video') {
                                                _showVideoPlayerModal(context, event['image_url']);
                                              }
                                            },
                                            child: ClipOval(
                                              child: event['media_type'] == 'video'
                                                  ? Container(
                                                      color: Colors.black87,
                                                      width: 80,
                                                      height: 80,
                                                      child: const Center(
                                                        child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32),
                                                      ),
                                                    )
                                                  : Image.network(
                                                      event['image_url'],
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.person,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () => _setAsProfilePhoto(
                                              event['image_url'],
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.deepPurple.shade300,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.star,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),

                                    // Textos
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event['age_text'] ??
                                                "Recém-nascido",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF2D3142),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            event['description'] ?? "",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: Colors.grey.shade400,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editTimelineEvent(event);
                                        } else if (value == 'delete') {
                                          _confirmDelete(event);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color:
                                                    Colors.deepPurple.shade300,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Editar",
                                                style: TextStyle(
                                                  color: Colors
                                                      .deepPurple
                                                      .shade300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delete,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                "Excluir",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  // Botoes fixos no rodape
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.8),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _addMedia,
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Adicionar Memória",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.deepPurple.shade300,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: _openStories,
                                icon: Icon(
                                  Icons.visibility,
                                  color: Colors.deepPurple.shade300,
                                ),
                                label: Text(
                                  "Ver como Stories",
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade300,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 70,
                            ), // Espaco da curved navigation bar
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  void _showVideoPlayerModal(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: VideoPlayerWidget(url: url),
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      })
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: _controller.value.isPlaying
                        ? const SizedBox.shrink()
                        : const Icon(Icons.play_arrow, size: 64, color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
  }
}

// Pintor para a linha tracejada
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tela de visualizacao estilo Stories
class StoriesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> events;

  const StoriesScreen({super.key, required this.events});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController =
        AnimationController(
            vsync: this,
            duration: const Duration(seconds: 5), // 5 segundos por foto
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextStory();
            }
          });

    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.events.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); // Fim dos stories
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty)
      return const Scaffold(backgroundColor: Colors.black);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Imagens
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _progressController.forward(from: 0.0);
              },
              physics:
                  const NeverScrollableScrollPhysics(), // Navegacao por toque
              itemCount: widget.events.length,
              itemBuilder: (context, index) {
                final event = widget.events[index];
                return GestureDetector(
                  onTapDown: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx < screenWidth / 3) {
                      _prevStory();
                    } else {
                      _nextStory();
                    }
                  },
                  onLongPressDown: (_) => _progressController.stop(),
                  onLongPressUp: () => _progressController.forward(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event['media_type'] == 'video')
                        Container(
                          color: Colors.black,
                          child: Center(
                            child: IgnorePointer(
                              // Ignorar toques para permitir avançar/voltar o story
                              child: VideoPlayerWidget(url: event['image_url']),
                            ),
                          ),
                        )
                      else
                        Image.network(
                          event['image_url'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      // Gradiente para melhorar legibilidade
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.3, 1.0],
                          ),
                        ),
                      ),
                      // Textos na parte inferior
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['age_text'] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['description'] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Barras de progresso
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(widget.events.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: LinearProgressIndicator(
                        value: index < _currentIndex
                            ? 1.0
                            : (index == _currentIndex
                                  ? _progressController.value
                                  : 0.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Fechar e Titulo superior
            Positioned(
              top: 30,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  if (widget.events[_currentIndex]['media_type'] == 'video')
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.videocam, color: Colors.white, size: 16),
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        widget.events[_currentIndex]['image_url'],
                      ),
                      onBackgroundImageError: (e, s) {},
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.events[_currentIndex]['title'] ?? "Memória",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
