// import 'dart:io'; // Removido para compatibilidade Web
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
// Para kIsWeb
import 'package:intl/intl.dart';

class DiaryScreen extends StatefulWidget {
  final Color themeColor;
  final String? familyId; // <--- A LINHA QUE FALTAVA PARA CORRIGIR O ERRO

  const DiaryScreen({
    super.key,
    required this.themeColor,
    this.familyId, // <--- AGORA ELE ACEITA O ID E O VERMELHO SOME
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedMood = 'Feliz';
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _moods = [
    {
      'label': 'Feliz',
      'icon': Icons.sentiment_very_satisfied,
      'color': Colors.green,
    },
    {'label': 'Cansada', 'icon': Icons.bedtime, 'color': Colors.blueGrey},
    {'label': 'Enjoada', 'icon': Icons.sick, 'color': Colors.greenAccent},
    {
      'label': 'Ansiosa',
      'icon': Icons.sentiment_neutral,
      'color': Colors.orange,
    },
    {
      'label': 'Triste',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.blue,
    },
  ];

  // Variável para controle de edição
  String? _editingId;

  Future<void> _addEntry() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (_noteController.text.isEmpty && _imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      String? uploadedImageUrl;
      // Se não mudou a imagem na edição, mantém a antiga?
      // Logica simples: Se _imageFile != null, upload. Se não, se edição, não mexe (mas user pode ter removido).
      // Na v1 vamos assumir upload novo substitui.

      if (_imageFile != null && _imageBytes != null) {
        final fileName =
            'docs/${user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('diary_photos')
            .uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        uploadedImageUrl = Supabase.instance.client.storage
            .from('diary_photos')
            .getPublicUrl(fileName);
      }

      final data = {
        'user_id': user!.id,
        'entry_date': DateTime.now()
            .toIso8601String(), // Mantém data original se for edição? Talvez update?
        // Se for edição, talvez manter a data original seja melhor, mas aqui simplificamos "editado hoje".
        // Vamos manter a lógica simples: se edição, update nos campos.
        'weight': double.tryParse(_weightController.text.replaceAll(',', '.')),
        'notes': _noteController.text,
        'mood': _selectedMood,
      };

      if (uploadedImageUrl != null) {
        data['photo_url'] = uploadedImageUrl;
      }

      if (_editingId != null) {
        await Supabase.instance.client
            .from('diary_entries')
            .update(data)
            .eq('id', _editingId!);
      } else {
        await Supabase.instance.client.from('diary_entries').insert(data);
      }

      _weightController.clear();
      _noteController.clear();
      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _selectedMood = 'Feliz';
        _isUploading = false;
        _editingId = null;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

  void _showAddEntrySheet({Map<String, dynamic>? entry}) {
    if (entry != null) {
      _editingId = entry['id'];
      _noteController.text = entry['notes'] ?? '';
      _weightController.text = entry['weight']?.toString() ?? '';
      _selectedMood = entry['mood'] ?? 'Feliz';
      // Image handling is tricky without downloading. We'll skip pre-filling image file for now,
      // but ideally show the existing url.
    } else {
      _editingId = null;
      _noteController.clear();
      _weightController.clear();
      _selectedMood = 'Feliz';
      _imageFile = null;
      _imageBytes = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(
                source: source,
                imageQuality: 50,
              );
              if (pickedFile != null) {
                final bytes = await pickedFile.readAsBytes();
                setStateSheet(() {
                  _imageFile = pickedFile;
                  _imageBytes = bytes;
                });
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: ListView(
                    controller: controller,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Como você está?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.themeColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _moods.map((mood) {
                            final isSelected = _selectedMood == mood['label'];
                            return GestureDetector(
                              onTap: () => setStateSheet(
                                () => _selectedMood = mood['label'],
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 15),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? mood['color'].withOpacity(0.2)
                                      : Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: mood['color'],
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: Colors.transparent,
                                          width: 2,
                                        ),
                                ),
                                child: Icon(
                                  mood['icon'],
                                  color: isSelected
                                      ? mood['color']
                                      : Colors.grey,
                                  size: 35,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _selectedMood,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Escreva sobre seu dia...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Peso atual (kg)",
                          prefixIcon: const Icon(Icons.monitor_weight),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (_imageFile != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: _imageBytes != null
                                  ? Image.memory(
                                      _imageBytes!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(height: 200),
                            ),
                            IconButton(
                              onPressed: () => setStateSheet(() {
                                _imageFile = null;
                                _imageBytes = null;
                              }),
                              icon: const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.close, color: Colors.red),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text("Tirar Foto"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo),
                                label: const Text("Galeria"),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: _isUploading ? null : _addEntry,
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Salvar no Diário",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Center(child: Text("Erro Auth"));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntrySheet,
        label: const Text("Registrar"),
        icon: const Icon(Icons.edit_note),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: Supabase.instance.client
            .from('diary_entries')
            .stream(primaryKey: ['id'])
            .eq('user_id', user.id)
            .order('entry_date', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    "Seu diário está vazio.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            reverse:
                true, // Chat usually starts from bottom? Or just normal? Let's keep normal top-down for diary.
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final date = DateTime.parse(entry['entry_date']);
              final moodData = _moods.firstWhere(
                (m) => m['label'] == (entry['mood'] ?? 'Feliz'),
                orElse: () => _moods[0],
              );

              // Chat Bubble Decoration
              return GestureDetector(
                onTap: () {
                  // Open Edit/View Sheet
                  // Here we ideally want to reuse the adding sheet but populated.
                  // For now, simpler View Dialog.
                  // But user asked to "edit".
                  // We'll reimplement _showEntryForm in a way it accepts data.
                  _showAddEntrySheet(entry: entry);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end, // My messages (Right)
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Time
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, right: 8),
                        child: Text(
                          DateFormat('dd/MM HH:mm').format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.themeColor.withOpacity(
                              0.1,
                            ), // User bubble color
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (entry['photo_url'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(entry['photo_url']),
                                  ),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    moodData['icon'],
                                    size: 16,
                                    color: moodData['color'],
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    moodData['label'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: moodData['color'],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (entry['notes'] != null &&
                                  entry['notes'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    entry['notes'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              if (entry['weight'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.monitor_weight,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${entry['weight']} kg",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
      ),
    );
  }
}
