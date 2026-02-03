import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar e colar
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

class SettingsScreen extends StatefulWidget {
  final Color themeColor;

  const SettingsScreen({super.key, required this.themeColor});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isEditingProfile = false;
  bool _isUploading = false;

  // --- DADOS DO USUÁRIO ---
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodTypeController =
      TextEditingController(); // Pode ser texto livre ou dropdown
  String? _photoUrl;
  String? _role;

  // --- DADOS DO BEBÊ (FAMÍLIA) ---
  final _babyNameController = TextEditingController();
  String _babyGender = 'neutro'; // 'menino', 'menina', 'neutro'
  String? _familyId;

  // --- DADOS DO PARCEIRO(A) ---
  Map<String, dynamic>? _partnerProfile;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final client = Supabase.instance.client;

      // 1. Carrega Perfil do Usuário
      final myProfile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // 2. Carrega Família (para nome do bebê e tema)
      _familyId = myProfile['family_id'];
      Map<String, dynamic>? familyData;

      if (_familyId != null) {
        familyData = await client
            .from('families')
            .select()
            .eq('id', _familyId!)
            .single();

        // 3. Carrega o Parceiro (Alguém da mesma família que NÃO sou eu)
        final partners = await client
            .from('profiles')
            .select()
            .eq('family_id', _familyId!)
            .neq('id', user.id) // Diferente de mim
            .limit(1); // Pega o primeiro que achar

        if (partners.isNotEmpty) {
          _partnerProfile = partners.first;
        }
      }

      if (mounted) {
        setState(() {
          // Set User
          _nameController.text = myProfile['full_name'] ?? '';
          _nicknameController.text = myProfile['nickname'] ?? '';
          _addressController.text = myProfile['address'] ?? '';
          _bloodTypeController.text = myProfile['blood_type'] ?? '';
          _photoUrl = myProfile['photo_url'];
          _role = myProfile['role'];
          if (_photoUrl != null)
            _photoUrl = "$_photoUrl?v=${DateTime.now().millisecondsSinceEpoch}";

          // Set Baby
          if (familyData != null) {
            _babyNameController.text = familyData['baby_name'] ?? 'Bebê';
            _babyGender = familyData['baby_gender'] ?? 'neutro';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SALVAR PERFIL DO USUÁRIO ---
  Future<void> _saveUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'nickname': _nicknameController.text,
            'address': _addressController.text,
            'blood_type': _bloodTypeController.text,
          })
          .eq('id', user.id);

      setState(() {
        _isEditingProfile = false;
        _isLoading = false;
      });
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Perfil atualizado!")));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  // --- SALVAR DADOS DO BEBÊ (TEMA) ---
  Future<void> _saveBabyData() async {
    if (_familyId == null) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('families')
          .update({
            'baby_name': _babyNameController.text,
            'baby_gender': _babyGender,
          })
          .eq('id', _familyId!);

      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dados do bebê atualizados!")),
        );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  // --- UPLOAD FOTO ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      final bytes = await picked.readAsBytes();
      final fileExt = picked.path.split('.').last;
      final fileName =
          '${user!.id}/profile_avatar.${fileExt}'; // Sobrescreve sempre o mesmo arquivo para economizar espaço

      await Supabase.instance.client.storage
          .from('diary_photos') // Usando mesmo bucket por simplicidade
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('diary_photos')
          .getPublicUrl(fileName);

      await Supabase.instance.client
          .from('profiles')
          .update({'photo_url': imageUrl})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          _photoUrl = "$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}";
          _isUploading = false;
        });
      }
    } catch (e) {
      print("Erro upload: $e");
      setState(() => _isUploading = false);
    }
  }

  void _copyToClipboard(String label, String? value) {
    if (value != null && value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$label copiado!"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Ajustes & Perfil"),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // 1. CARD MEU PERFIL (FOTO ESQUERDA, DADOS DIREITA)
            // ============================================
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                "MEU PERFIL",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ESQUERDA: FOTO
                        Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.themeColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: _photoUrl != null
                                        ? NetworkImage(_photoUrl!)
                                        : null,
                                    child: _photoUrl == null
                                        ? Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey[400],
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _isUploading
                                        ? null
                                        : _pickAndUploadImage,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: widget.themeColor,
                                      child: _isUploading
                                          ? const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _role == 'mae'
                                  ? 'Mamãe'
                                  : (_role == 'pai' ? 'Papai' : 'Usuário'),
                              style: TextStyle(
                                color: widget.themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 20),

                        // DIREITA: CAMPOS EDITÁVEIS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildEditableField(
                                "Apelido",
                                _nicknameController,
                                _isEditingProfile,
                                Icons.face,
                              ),
                              const SizedBox(height: 10),
                              _buildEditableField(
                                "Endereço",
                                _addressController,
                                _isEditingProfile,
                                Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 10),
                              _buildEditableField(
                                "Tipo Sanguíneo",
                                _bloodTypeController,
                                _isEditingProfile,
                                Icons.bloodtype,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // BOTÃO EDITAR / SALVAR
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _isEditingProfile
                            ? _saveUserProfile()
                            : setState(() => _isEditingProfile = true),
                        icon: Icon(_isEditingProfile ? Icons.save : Icons.edit),
                        label: Text(
                          _isEditingProfile
                              ? "Salvar Alterações"
                              : "Editar Meus Dados",
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.themeColor,
                          side: BorderSide(color: widget.themeColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ============================================
            // 2. CARD DO PARCEIRO (APENAS VISUALIZAR E COPIAR)
            // ============================================
            if (_partnerProfile != null) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  "DADOS DO PARCEIRO(A)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Card(
                elevation: 2,
                color: Colors.blueGrey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                _partnerProfile!['photo_url'] != null
                                ? NetworkImage(_partnerProfile!['photo_url'])
                                : null,
                            child: _partnerProfile!['photo_url'] == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _partnerProfile!['nickname'] ?? 'Sem apelido',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _partnerProfile!['role'] == 'mae'
                                      ? 'Mamãe'
                                      : 'Papai',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildPartnerInfoRow(
                        Icons.badge,
                        "Nome Completo",
                        _partnerProfile!['full_name'],
                      ),
                      _buildPartnerInfoRow(
                        Icons.location_on,
                        "Endereço",
                        _partnerProfile!['address'],
                      ),
                      _buildPartnerInfoRow(
                        Icons.bloodtype,
                        "Tipo Sanguíneo",
                        _partnerProfile!['blood_type'],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],

            // ============================================
            // 3. CONFIGURAÇÕES DO BEBÊ (TEMA E NOME)
            // ============================================
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                "CONFIGURAÇÕES DO APP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _babyNameController,
                      decoration: const InputDecoration(
                        labelText: "Nome do Bebê",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _babyGender,
                      decoration: const InputDecoration(
                        labelText: "Sexo do Bebê (Define a Cor)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.palette),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'menino',
                          child: Text("Menino (Azul)"),
                        ),
                        DropdownMenuItem(
                          value: 'menina',
                          child: Text("Menina (Rosa)"),
                        ),
                        DropdownMenuItem(
                          value: 'neutro',
                          child: Text("Surpresa (Roxo)"),
                        ),
                      ],
                      onChanged: (v) => setState(() => _babyGender = v!),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveBabyData,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Aplicar Tema e Nome"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // BOTÃO SAIR
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Sair da Conta",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  // Campo editável do usuário
  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    bool isEditing,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        isEditing
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  controller.text.isNotEmpty ? controller.text : '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ],
    );
  }

  // Linha de informação do parceiro com botão copiar
  Widget _buildPartnerInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
            onPressed: () => _copyToClipboard(label, value),
            tooltip: "Copiar $label",
            constraints: const BoxConstraints(), // Remove padding extra
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
