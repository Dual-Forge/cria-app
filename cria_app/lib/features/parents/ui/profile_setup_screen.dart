// import 'dart:io'; // Removido para compatibilidade Web
import 'dart:math';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'main_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Controladores
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _birthDateController = TextEditingController();

  // Variáveis de Estado
  String _selectedRole = 'mae'; // 'mae' ou 'pai'
  String? _selectedBloodType;
  bool _isJoiningFamily = false;
  bool _isLoading = false;
  DateTime? _selectedDate;

  // Imagem
  XFile? _imageFile;
  Uint8List? _webImageBytes;
  String? _uploadedPhotoUrl;

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Não sei',
  ];

  // --- FUNÇÃO DE IMAGEM (Híbrida) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (picked != null) {
      setState(() => _imageFile = picked);
      final bytes = await picked.readAsBytes();
      setState(() => _webImageBytes = bytes);
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return null;

    try {
      final fileName =
          'avatars/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb && _webImageBytes != null) {
        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              _webImageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else {
        // No Mobile usamos o path do XFile, o Supabase SDK cuida do resto
        // ou podemos ler como bytes para ser universal
        final bytes = await _imageFile!.readAsBytes();
        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }

      return Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
    } catch (e) {
      print("Erro upload: $e");
      return null;
    }
  }

  // --- LÓGICA DE SALVAR ---
  Future<void> _submit() async {
    if (_fullNameController.text.isEmpty || _nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preencha nome e apelido.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw "Erro de autenticação";

      // 1. Upload da Foto (se tiver)
      String? photoUrl = await _uploadImage(user.id);

      String familyId;

      // 2. Lógica da Família (Criar ou Entrar)
      if (_isJoiningFamily) {
        final code = _inviteCodeController.text.trim().toUpperCase();
        if (code.isEmpty) throw "Digite o código da família.";

        final familyData = await Supabase.instance.client
            .from('families')
            .select('id')
            .eq('invite_code', code)
            .maybeSingle();

        if (familyData == null) throw "Código inválido.";
        familyId = familyData['id'];
      } else {
        final newCode = _generateInviteCode();
        final newFamily = await Supabase.instance.client
            .from('families')
            .insert({
              'invite_code': newCode,
              'created_by': user.id,
              'baby_name': 'Bebê',
              'baby_gender': 'neutro',
            })
            .select()
            .single();
        familyId = newFamily['id'];
      }

      // 3. Salvar Perfil Completo
      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'full_name': _fullNameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'role': _selectedRole,
        'birth_date': _selectedDate?.toIso8601String(),
        'blood_type': _selectedBloodType,
        'photo_url': photoUrl,
        'family_id': familyId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.purple;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Criar Perfil"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- 1. FOTO DE PERFIL ---
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor.withOpacity(0.5),
                        width: 2,
                      ),
                      image: (_webImageBytes != null)
                          ? DecorationImage(
                              image: MemoryImage(_webImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (_webImageBytes == null)
                        ? Icon(
                            Icons.person_add,
                            size: 50,
                            color: Colors.grey[400],
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Toque para adicionar foto",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),

            const SizedBox(height: 30),

            // --- 2. DADOS PESSOAIS ---
            _buildSectionTitle("Sobre Você"),

            TextField(
              controller: _fullNameController,
              decoration: _inputDecoration("Nome Completo", Icons.person),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    decoration: _inputDecoration("Apelido", Icons.face),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: _inputDecoration("Sou...", Icons.people),
                    items: const [
                      DropdownMenuItem(value: 'mae', child: Text("Mamãe")),
                      DropdownMenuItem(value: 'pai', child: Text("Papai")),
                    ],
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _birthDateController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      "Nascimento",
                      Icons.calendar_today,
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1995),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _birthDateController.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(picked);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBloodType,
                    decoration: _inputDecoration("Sangue", Icons.water_drop),
                    items: _bloodTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBloodType = v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 3. FAMÍLIA ---
            _buildSectionTitle("Sua Família"),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text("Criar nova família"),
                    subtitle: const Text("Primeira pessoa a baixar"),
                    value: false,
                    groupValue: _isJoiningFamily,
                    activeColor: themeColor,
                    onChanged: (val) => setState(() => _isJoiningFamily = val!),
                  ),
                  RadioListTile<bool>(
                    title: const Text("Entrar em família"),
                    subtitle: const Text("Tenho um código de convite"),
                    value: true,
                    groupValue: _isJoiningFamily,
                    activeColor: themeColor,
                    onChanged: (val) => setState(() => _isJoiningFamily = val!),
                  ),

                  if (_isJoiningFamily)
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: TextField(
                        controller: _inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _inputDecoration(
                          "Código da Família (6 letras)",
                          Icons.key,
                        ).copyWith(filled: true, fillColor: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: themeColor.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Finalizar Cadastro",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.purple, width: 2),
      ),
      prefixIcon: Icon(icon, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
          ),
        ),
      ),
    );
  }
}
