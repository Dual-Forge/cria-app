import 'dart:io';
import 'package:flutter/foundation.dart'; // Importante para detectar Web
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  final Color themeColor;
  const SettingsScreen({super.key, required this.themeColor});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _dumController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _familyCode;
  String? _photoUrl;
  String? _selectedGender;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (profile['family_id'] != null) {
        final family = await Supabase.instance.client
            .from('families')
            .select()
            .eq('id', profile['family_id'])
            .single();

        setState(() {
          _photoUrl = profile['photo_url'];
          _nameController.text = family['baby_name'] ?? '';
          _addressController.text = family['address'] ?? '';
          _selectedGender = family['baby_gender'];
          _familyCode = family['invite_code'];

          if (family['dum_date'] != null) {
            final dum = DateTime.parse(family['dum_date']);
            _dumController.text = DateFormat('dd/MM/yyyy').format(dum);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNÇÃO DE UPLOAD HÍBRIDA (WEB + MOBILE) ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (picked != null) {
      setState(() => _isLoading = true);
      try {
        final user = Supabase.instance.client.auth.currentUser;
        final fileExt = picked.path.split('.').last; // Tenta pegar extensão
        final fileName =
            'avatars/${user!.id}_${DateTime.now().millisecondsSinceEpoch}.${fileExt.length > 4 ? "jpg" : fileExt}';

        if (kIsWeb) {
          // LÓGICA WEB (Envia Bytes)
          final bytes = await picked.readAsBytes();
          await Supabase.instance.client.storage
              .from('avatars')
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
        } else {
          // LÓGICA MOBILE (Envia Arquivo)
          final file = File(picked.path);
          await Supabase.instance.client.storage
              .from('avatars')
              .upload(fileName, file);
        }

        final publicUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName);

        // Atualiza Cache da URL para aparecer na hora
        final timestampedUrl =
            "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";

        await Supabase.instance.client
            .from('profiles')
            .update({
              'photo_url': publicUrl, // Salva a URL limpa no banco
            })
            .eq('id', user.id);

        setState(() {
          _photoUrl =
              timestampedUrl; // Usa a URL com timestamp no app para forçar atualização
          _isLoading = false;
        });

        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Foto atualizada!")));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erro na foto: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    try {
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text.length < 6)
          throw "A senha deve ter no mínimo 6 caracteres.";
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
        _passwordController.clear();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Senha alterada com sucesso!")),
          );
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('family_id')
          .eq('id', user!.id)
          .single();
      Map<String, dynamic> updates = {
        'baby_name': _nameController.text,
        'baby_gender': _selectedGender,
        'address': _addressController.text,
      };
      if (_dumController.text.isNotEmpty) {
        try {
          final parts = _dumController.text.split('/');
          final date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          updates['dum_date'] = date.toIso8601String();
        } catch (_) {}
      }
      await Supabase.instance.client
          .from('families')
          .update(updates)
          .eq('id', profile['family_id']);

      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Dados salvos!")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyCode() {
    if (_familyCode != null) {
      Clipboard.setData(ClipboardData(text: _familyCode!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Código copiado!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Ajustes"),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: widget.themeColor,
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: _photoUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Toque para alterar foto",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nome do Bebê",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.child_care),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: "Sexo do Bebê",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette),
              ),
              items: const [
                DropdownMenuItem(value: 'menino', child: Text("Menino (Azul)")),
                DropdownMenuItem(value: 'menina', child: Text("Menina (Rosa)")),
                DropdownMenuItem(value: 'neutro', child: Text("Neutro (Roxo)")),
              ],
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _dumController,
              decoration: const InputDecoration(
                labelText: "DUM (Última Menstruação)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.datetime,
              onTap: () async {
                FocusScope.of(context).requestFocus(FocusNode());
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (picked != null)
                  _dumController.text = DateFormat('dd/MM/yyyy').format(picked);
              },
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Endereço da Família",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.red.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: Colors.red.shade300),
                      const SizedBox(width: 10),
                      Text(
                        "Segurança",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Nova Senha (Opcional)",
                      border: OutlineInputBorder(),
                      helperText: "Preencha apenas se quiser alterar a senha",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (_familyCode != null) ...[
              InkWell(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(
                        _familyCode!,
                        style: const TextStyle(fontSize: 18, letterSpacing: 2),
                      ),
                      const SizedBox(width: 15),
                      Icon(Icons.copy, color: widget.themeColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Código da Família",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Salvar Alterações"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
