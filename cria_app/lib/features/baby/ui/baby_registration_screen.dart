import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cria_app/features/parents/ui/main_screen.dart';

class BabyRegistrationScreen extends StatefulWidget {
  const BabyRegistrationScreen({super.key});

  @override
  State<BabyRegistrationScreen> createState() => _BabyRegistrationScreenState();
}

class _BabyRegistrationScreenState extends State<BabyRegistrationScreen> {
  final _nameController = TextEditingController();
  String? _selectedGender; // 'menino', 'menina' ou null
  bool _isLoading = false;

  // Função para Salvar e Redirecionar
  Future<void> _saveBabyData() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    try {
      // 1. Pega o ID da família do usuário atual
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .single();

      if (profile['family_id'] != null) {
        // 2. Atualiza a tabela families com o nome e sexo
        await Supabase.instance.client
            .from('families')
            .update({
              'baby_name': _nameController.text.isEmpty
                  ? null
                  : _nameController.text,
              'baby_gender': _selectedGender,
            })
            .eq('id', profile['family_id']);

        if (mounted) {
          // 3. NAVEGAÇÃO CORRETA (Aqui estava o erro)
          // Vamos para MainScreen, que vai ler se é Menino/Menina e pintar o app
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false, // Remove todas as telas anteriores da pilha
          );
        }
      } else {
        // Caso de erro raro (usuário sem família)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro: Família não encontrada.")),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalhes do Bebê")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            const Text(
              "Menino ou Menina?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Isso vai definir as cores e o tema do aplicativo para você e seu parceiro(a)!",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Campo Nome
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Nome do Bebê (Opcional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.abc),
                helperText: "Você pode mudar isso depois nos Ajustes",
              ),
            ),
            const SizedBox(height: 20),

            // Seleção de Sexo
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: "Sexo do Bebê",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'menino',
                  child: Text("Menino 💙 (Tema Azul)"),
                ),
                DropdownMenuItem(
                  value: 'menina',
                  child: Text("Menina 🩷 (Tema Rosa)"),
                ),
              ],
              onChanged: (v) => setState(() => _selectedGender = v),
              hint: const Text("Surpresa / Ainda não sei"),
            ),

            const SizedBox(height: 40),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBabyData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Salvar e Entrar"),
              ),
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Pular essa etapa (vai para a MainScreen direto)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              },
              child: const Text("Decidir depois (Pular)"),
            ),
          ],
        ),
      ),
    );
  }
}
