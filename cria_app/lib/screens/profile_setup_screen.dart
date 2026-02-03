import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  String _selectedRole = 'mae'; // 'mae' ou 'pai'
  bool _isJoiningFamily = false; // Alterna entre Criar ou Entrar
  bool _isLoading = false;

  // Gera código aleatório de 6 letras (Ex: AB3D9F)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    final user = Supabase.instance.client.auth.currentUser;

    if (nickname.isEmpty || user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Digite seu nome/apelido.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String familyId;

      if (_isJoiningFamily) {
        // --- ENTRAR EM FAMÍLIA EXISTENTE ---
        final code = _inviteCodeController.text.trim().toUpperCase();
        if (code.isEmpty) throw "Digite o código da família.";

        // Busca a família pelo código
        final familyData = await Supabase.instance.client
            .from('families')
            .select('id')
            .eq('invite_code', code)
            .maybeSingle();

        if (familyData == null)
          throw "Código inválido ou família não encontrada.";
        familyId = familyData['id'];
      } else {
        // --- CRIAR NOVA FAMÍLIA ---
        final newCode = _generateInviteCode();

        // Cria a família na tabela families
        final newFamily = await Supabase.instance.client
            .from('families')
            .insert({
              'invite_code': newCode,
              'created_by': user.id,
              // Define padrões iniciais
              'baby_name': 'Bebê',
              'baby_gender': 'neutro',
            })
            .select()
            .single();

        familyId = newFamily['id'];
      }

      // --- CRIA O PERFIL DO USUÁRIO ---
      // Agora vinculamos o usuário a essa família
      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'nickname': nickname,
        'role': _selectedRole,
        'family_id': familyId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Tudo certo? Vai para a Home!
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Finalizar Cadastro"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Olá! Quem é você?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Apelido
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: "Seu Nome ou Apelido",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Papel (Mãe ou Pai)
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: "Sou...",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'mae', child: Text("Mamãe")),
                DropdownMenuItem(value: 'pai', child: Text("Papai")),
              ],
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 30),

            // Alternar Criar/Entrar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Criar nova família"),
                          subtitle: const Text(
                            "Sou a primeira pessoa a baixar",
                          ),
                          value: false,
                          groupValue: _isJoiningFamily,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) =>
                              setState(() => _isJoiningFamily = val!),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Entrar em família"),
                          subtitle: const Text("Já tenho um código de convite"),
                          value: true,
                          groupValue: _isJoiningFamily,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) =>
                              setState(() => _isJoiningFamily = val!),
                        ),
                      ),
                    ],
                  ),

                  // Campo do Código (Só aparece se for Entrar)
                  if (_isJoiningFamily)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        controller: _inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: "Digite o Código (6 letras)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                          hintText: "Ex: A1B2C3",
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Começar!", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
