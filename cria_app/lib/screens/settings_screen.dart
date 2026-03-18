import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _bloodTypeController = TextEditingController();
  String? _photoUrl;
  String? _role;
  DateTime? _dumDate; // Variável para a Data da Última Menstruação

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

  // Lógica para calcular semanas e dias a partir da DUM
  Map<String, int> calcularIdadeGestacional(DateTime? dum) {
    if (dum == null) return {'semanas': 0, 'dias': 0};
    final hoje = DateTime.now();
    final diferencaEmDias = hoje.difference(dum).inDays;
    return {'semanas': diferencaEmDias ~/ 7, 'dias': diferencaEmDias % 7};
  }

  String _withCacheBuster(String url) {
    final uri = Uri.parse(url);
    if (uri.hasQuery) return url;
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
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

      // 2. Carrega Família
      _familyId = myProfile['family_id'];
      Map<String, dynamic>? familyData;

      if (_familyId != null) {
        familyData = await client
            .from('families')
            .select()
            .eq('id', _familyId!)
            .single();
      }

      if (mounted) {
        setState(() {
          _nameController.text = myProfile['full_name'] ?? '';
          _nicknameController.text = myProfile['nickname'] ?? '';
          _addressController.text = myProfile['address'] ?? '';
          _bloodTypeController.text = myProfile['blood_type'] ?? '';
          _photoUrl = myProfile['photo_url'];

          if (_photoUrl != null) {
            _photoUrl = _withCacheBuster(_photoUrl!);
          }

          _role = myProfile['role'];

          // Carregar a DUM se existir
          if (myProfile['dum_date'] != null) {
            _dumDate = DateTime.parse(myProfile['dum_date']);
          }

          if (familyData != null) {
            _babyNameController.text = familyData['baby_name'] ?? 'Bebê';
            _babyGender = familyData['baby_gender'] ?? 'neutro';
          }

          _isLoading = false;
        });

        // 3. Carregar Parceiro (agora mais robusto)
        if (_familyId != null) {
          try {
            final List<dynamic> response = await client
                .from('profiles')
                .select()
                .eq('family_id', _familyId!)
                .neq('id', user.id)
                .limit(1); // Pega apenas um, se houver

            if (mounted && response.isNotEmpty) {
              setState(() {
                _partnerProfile = response.first as Map<String, dynamic>;
              });
            }
          } catch (e) {
            print("Erro ao carregar parceiro: $e");
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SELECIONAR DUM ---
  Future<void> _selectDumDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dumDate ?? DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() => _isLoading = true);
      try {
        final user = Supabase.instance.client.auth.currentUser;
        await Supabase.instance.client
            .from('profiles')
            .update({'dum_date': picked.toIso8601String().split('T')[0]})
            .eq('id', user!.id);

        setState(() {
          _dumDate = picked;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        print("Erro ao salvar DUM: $e");
      }
    }
  }

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Perfil atualizado!")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dados do bebê atualizados!")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

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

      // Na Web, usamos o 'name' para pegar a extensão, pois o 'path' é virtual
      final String fileExt = picked.name.split('.').last.toLowerCase();
      final String fileName = '${user!.id}/profile_avatar.$fileExt';

      // Forçamos um contentType limpo para evitar o erro 'image/app/...'
      final String contentType = 'image/$fileExt';

      await Supabase.instance.client.storage
          .from('diary_photos')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
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
          // Timestamp para limpar o cache do navegador
          _photoUrl = "$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}";
          _isUploading = false;
        });
      }
    } catch (e) {
      print("Erro upload: $e");
      if (mounted) setState(() => _isUploading = false);
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Ajustes & Perfil"),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // PROFILE HEADER
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.themeColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _photoUrl != null
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: _photoUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.themeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : "Olá, Mamãe",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    _role == 'mae'
                        ? 'Mamãe'
                        : (_role == 'pai' ? 'Papai' : 'Usuário'),
                    style: TextStyle(
                      color: widget.themeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // PERSONAL INFO SECTION
            _buildSectionHeader("Meus Dados"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildModernField(
                    "Apelido",
                    _nicknameController,
                    _isEditingProfile,
                    Icons.face,
                  ),
                  const Divider(height: 30, color: Colors.black12),
                  _buildModernField(
                    "Endereço",
                    _addressController,
                    _isEditingProfile,
                    Icons.location_on_outlined,
                  ),
                  const Divider(height: 30, color: Colors.black12),
                  _buildModernField(
                    "Tipo Sanguíneo",
                    _bloodTypeController,
                    _isEditingProfile,
                    Icons.bloodtype,
                  ),
                  if (_role == 'mae') ...[
                    const Divider(height: 30, color: Colors.black12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: widget.themeColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Idade Gestacional",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final gest = calcularIdadeGestacional(
                                    _dumDate,
                                  );
                                  return Text(
                                    _dumDate == null
                                        ? "Definir DUM"
                                        : "${gest['semanas']} sem + ${gest['dias']} dias",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _selectDumDate(context),
                          child: const Text("Alterar"),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _isEditingProfile
                          ? _saveUserProfile()
                          : setState(() => _isEditingProfile = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditingProfile
                            ? widget.themeColor
                            : Colors.grey[100],
                        foregroundColor: _isEditingProfile
                            ? Colors.white
                            : widget.themeColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        _isEditingProfile ? "Salvar Alterações" : "Editar",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // PARTNER INFO SECTION (Dados da Mamãe/Parceiro)
            if (_partnerProfile != null) ...[
              _buildSectionHeader(
                _role == 'mae' ? "Meu Parceiro" : "Dados da Mamãe",
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // PARTNER PHOTO
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.themeColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              (_partnerProfile!['photo_url'] != null &&
                                  _partnerProfile!['photo_url']
                                      .toString()
                                      .isNotEmpty)
                              ? NetworkImage(_partnerProfile!['photo_url'])
                              : null,
                          child:
                              (_partnerProfile!['photo_url'] == null ||
                                  _partnerProfile!['photo_url']
                                      .toString()
                                      .isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 35,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildPartnerInfoRow(
                      Icons.person,
                      "Nome Completo",
                      _partnerProfile!['full_name'],
                    ),
                    const Divider(height: 15, color: Colors.black12),

                    if (_partnerProfile!['nickname'] != null &&
                        _partnerProfile!['nickname'].toString().isNotEmpty) ...[
                      _buildPartnerInfoRow(
                        Icons.face,
                        "Apelido",
                        _partnerProfile!['nickname'],
                      ),
                      const Divider(height: 15, color: Colors.black12),
                    ],

                    _buildPartnerInfoRow(
                      Icons.phone,
                      "Telefone",
                      _partnerProfile!['phone'],
                    ),
                    const Divider(height: 15, color: Colors.black12),

                    _buildPartnerInfoRow(
                      Icons.location_on,
                      "Endereço",
                      _partnerProfile!['address'],
                    ),
                    const Divider(height: 15, color: Colors.black12),

                    _buildPartnerInfoRow(
                      Icons.bloodtype,
                      "Tipo Sanguíneo",
                      _partnerProfile!['blood_type'],
                    ),

                    if (_role != 'mae' &&
                        _partnerProfile!['dum_date'] != null) ...[
                      const Divider(height: 15, color: Colors.black12),
                      Builder(
                        builder: (context) {
                          final dum = DateTime.parse(
                            _partnerProfile!['dum_date'],
                          );
                          final gest = calcularIdadeGestacional(dum);
                          return _buildPartnerInfoRow(
                            Icons.calendar_month,
                            "Gestação (Mamãe)",
                            "${gest['semanas']} semanas + ${gest['dias']} dias",
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],

            const SizedBox(height: 10),

            // BABY CONFIG SECTION
            _buildSectionHeader("Configurações do Bebê"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _babyNameController,
                    decoration: InputDecoration(
                      labelText: "Nome do Bebê",
                      prefixIcon: const Icon(Icons.child_care),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_familyId != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: widget.themeColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.themeColor.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.link, color: widget.themeColor),
                        title: const Text(
                          "Meu Link de Presentes Público",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "app-cria.vercel.app/presentes/$_familyId",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          color: widget.themeColor,
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    'https://web-jade-ten-51.vercel.app/presentes/$_familyId',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Link copiado para a área de transferência!',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: _babyGender,
                    decoration: InputDecoration(
                      labelText: "Sexo do Bebê",
                      prefixIcon: const Icon(Icons.palette),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveBabyData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text("Aplicar Tema"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // INVITE CODE & LOGOUT
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                // WRAP LIST TILES
                children: [
                  FutureBuilder(
                    future: Supabase.instance.client
                        .from('profiles')
                        .select('family_id, families(invite_code)')
                        .eq('id', Supabase.instance.client.auth.currentUser!.id)
                        .single(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.hasError ||
                          snapshot.data == null ||
                          snapshot.data['families'] == null) {
                        return const SizedBox.shrink();
                      }

                      final String inviteCode = snapshot
                          .data['families']['invite_code']
                          .toString();

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.share, color: Colors.purple),
                        ),
                        title: const Text("Código de Convite"),
                        subtitle: Text(
                          inviteCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () =>
                              _copyToClipboard("Código de convite", inviteCode),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text(
                      "Sair da Conta",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildModernField(
    String label,
    TextEditingController controller,
    bool isEditing,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blueGrey, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              isEditing
                  ? SizedBox(
                      height: 35,
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  : Text(
                      controller.text.isNotEmpty ? controller.text : '-',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // RE-ADDED: Helper for partner info
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
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
