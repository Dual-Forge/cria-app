import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/parents/timeline/memory_event.dart';
import 'age_input_field.dart';
import 'media_preview_tile.dart';

/// Resultado do formulário de memória.
///
/// Para criação, [bytes]/[ext]/[contentType] descrevem o upload. [isVideo]
/// indica o tipo de mídia; `clipStartMs`/`clipEndMs` são opcionais e definem
/// o trecho de vídeo (≤ 1 min) a reproduzir. `null` = cancelado.
class MemoryFormResult {
  final Uint8List bytes;
  final String ext;
  final String contentType;
  final String title;
  final String description;
  final String ageText;
  final DateTime date;
  final bool isVideo;
  final int? clipStartMs;
  final int? clipEndMs;

  const MemoryFormResult({
    required this.bytes,
    required this.ext,
    required this.contentType,
    required this.title,
    required this.description,
    required this.ageText,
    required this.date,
    required this.isVideo,
    this.clipStartMs,
    this.clipEndMs,
  });
}

/// Abre o formulário para ADICIONAR uma memória.
///
/// [media] descreve a mídia já selecionada; `media.clipStartMs/clipEndMs`
/// carregam o trecho escolhido (se o vídeo foi cortado antes de abrir o form).
Future<void> showAddMemorySheet({
  required BuildContext context,
  required AddMemoryMedia media,
  required Future<void> Function(MemoryFormResult result) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (ctx) => _MemoryFormSheet(
      media: media,
      onSubmit: onSubmit,
    ),
  );
}

/// Abre o formulário para EDITAR uma memória (metadados apenas).
Future<void> showEditMemorySheet({
  required BuildContext context,
  required MemoryEvent event,
  required Future<void> Function({
    required String title,
    required String description,
    required String ageText,
    required DateTime date,
  })
  onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (ctx) => _MemoryFormSheet(
      media: null,
      isEditing: true,
      initialEvent: event,
      onSubmit: (r) => onSubmit(
        title: r.title,
        description: r.description,
        ageText: r.ageText,
        date: r.date,
      ),
    ),
  );
}

/// Dados da mídia escolhida para upload (imagem ou vídeo).
class AddMemoryMedia {
  final Uint8List bytes;
  final String filePath;
  final String ext;
  final String contentType;
  final bool isVideo;

  /// Trecho de vídeo escolhido no trimmer (só para vídeos longos).
  final int? clipStartMs;
  final int? clipEndMs;

  const AddMemoryMedia({
    required this.bytes,
    required this.filePath,
    required this.ext,
    required this.contentType,
    required this.isVideo,
    this.clipStartMs,
    this.clipEndMs,
  });
}

class _MemoryFormSheet extends StatefulWidget {
  final AddMemoryMedia? media;
  final bool isEditing;
  final MemoryEvent? initialEvent;
  final Future<void> Function(MemoryFormResult result)? onSubmit;

  const _MemoryFormSheet({
    this.media,
    this.isEditing = false,
    this.initialEvent,
    this.onSubmit,
  });

  @override
  State<_MemoryFormSheet> createState() => _MemoryFormSheetState();
}

class _MemoryFormSheetState extends State<_MemoryFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  late AgePeriod _agePeriod;
  late String _ageText;
  late DateTime _selectedDate;

  bool _submitting = false;
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    final evt = widget.initialEvent;

    _titleController = TextEditingController(text: evt?.title ?? '');
    _descController = TextEditingController(text: evt?.description ?? '');
    _selectedDate = evt?.date ?? DateTime.now();

    final parsed = parseLegacyAgeText(evt?.ageText);
    _agePeriod = parsed.$1;
    _ageText = evt?.ageText ?? '';

    _titleController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty && _ageText.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    setState(() => _triedSubmit = true);
    if (!_isValid || _submitting) return;

    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final media = widget.media;
      if (!widget.isEditing && widget.onSubmit != null && media != null) {
        await widget.onSubmit!(
          MemoryFormResult(
            bytes: media.bytes,
            ext: media.ext,
            contentType: media.contentType,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            ageText: _ageText.trim(),
            date: _selectedDate,
            isVideo: media.isVideo,
            clipStartMs: media.clipStartMs,
            clipEndMs: media.clipEndMs,
          ),
        );
      }
      navigator.pop();
    } catch (e) {
      debugPrint('[MemoryForm] Erro ao salvar: $e');
      setState(() => _submitting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Erro ao salvar a memória.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.isEditing ? 'Editar Memória' : 'Nova Memória',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Prévia da mídia (somente na criação)
              if (!widget.isEditing && media != null) ...[
                MediaPreviewTile(
                  filePath: media.filePath,
                  bytes: media.bytes,
                  isVideo: media.isVideo,
                ),
                const SizedBox(height: 12),
                // Trecho de vídeo selecionado (corte suave)
                if (media.isVideo &&
                    media.clipStartMs != null &&
                    media.clipEndMs != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.content_cut,
                            color: Colors.deepPurple, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Trecho: ${_fmtMs(media.clipStartMs!)} — ${_fmtMs(media.clipEndMs!)} '
                            '(${_fmtMs(media.clipEndMs! - media.clipStartMs!)})',
                            style: TextStyle(
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Idade (obrigatória)
              AgeInputField(
                initialPeriod: _agePeriod,
                initialValue: _parseValue(_ageText),
                onAgeTextChanged: (t) => setState(() => _ageText = t),
              ),
              if (_triedSubmit && _ageText.trim().isEmpty)
                _buildError('Informe a idade.'),

              const SizedBox(height: 12),

              // Título (obrigatório)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  hintText: 'ex: Primeiro Sorriso',
                  errorText:
                      _triedSubmit && _titleController.text.trim().isEmpty
                          ? 'O título é obrigatório.'
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Descrição (opcional)
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'O que aconteceu? (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Data (obrigatória)
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Ações
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
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Salvar Memória',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _parseValue(String text) {
    final m = RegExp(r'(\d+)').firstMatch(text);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  String _fmtMs(int ms) {
    final s = (ms / 1000).round();
    final m = s ~/ 60;
    final r = s % 60;
    final sec = r.toString().padLeft(2, '0');
    return m > 0 ? '$m:$sec' : '0:$sec';
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade600, fontSize: 12),
      ),
    );
  }
}