import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
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
  File? _imageFile;
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

  Future<void> _addEntry() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (_noteController.text.isEmpty && _imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      String? uploadedImageUrl;
      if (_imageFile != null) {
        final fileName =
            'docs/${user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('diary_photos')
            .upload(fileName, _imageFile!);
        uploadedImageUrl = Supabase.instance.client.storage
            .from('diary_photos')
            .getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('diary_entries').insert({
        'user_id': user!.id,
        // Usamos o user_id como na V1, mas o familyId está disponível se precisar no futuro
        'entry_date': DateTime.now().toIso8601String(),
        'weight': double.tryParse(_weightController.text.replaceAll(',', '.')),
        'notes': _noteController.text,
        'mood': _selectedMood,
        'photo_url': uploadedImageUrl,
      });

      _weightController.clear();
      _noteController.clear();
      setState(() {
        _imageFile = null;
        _selectedMood = 'Feliz';
        _isUploading = false;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void _showAddEntrySheet() {
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
              if (pickedFile != null)
                setStateSheet(() => _imageFile = File(pickedFile.path));
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
                              child: Image.file(
                                _imageFile!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setStateSheet(() => _imageFile = null),
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
      backgroundColor: Colors.grey[50],
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final entries = snapshot.data!;
          if (entries.isEmpty)
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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final date = DateTime.parse(entry['entry_date']);
              final moodData = _moods.firstWhere(
                (m) => m['label'] == (entry['mood'] ?? 'Feliz'),
                orElse: () => _moods[0],
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry['photo_url'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Image.network(
                          entry['photo_url'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy • HH:mm').format(date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.themeColor,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: moodData['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      moodData['icon'],
                                      color: moodData['color'],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      moodData['label'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: moodData['color'],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (entry['notes'] != null)
                            Text(
                              entry['notes'],
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                          if (entry['weight'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.monitor_weight_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Peso: ${entry['weight']} kg",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
