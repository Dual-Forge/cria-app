import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart'; // Importante: Certifique-se que o nome do arquivo da tela principal está correto

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // Função de Login
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      // Tenta fazer o login anônimo no Supabase
      // (Certifique-se que "Anonymous Sign-ins" está ativado no painel do Supabase)
      await Supabase.instance.client.auth.signInAnonymously();
      
      // Se der certo e a tela ainda estiver aberta, navega para a Home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      // Se der erro, mostra uma barra vermelha embaixo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao entrar: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Para o ícone de carregamento
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo roxo bem clarinho
      backgroundColor: Colors.purple.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Ícone ou Logo ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Icon(Icons.child_friendly, size: 80, color: Colors.purple.shade300),
              ),
              
              const SizedBox(height: 30),
              
              // --- Textos de Boas-vindas ---
              const Text(
                "Bem-vinda ao Cria",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.purple
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Acompanhe sua gravidez, enxoval\ne diário em um só lugar.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              
              const SizedBox(height: 60),

              // --- Botão de Entrar ---
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Entrar como Convidado",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                
              const SizedBox(height: 20),
              
              // Nota de rodapé (Opcional)
              const Text(
                "Seus dados ficam salvos neste dispositivo.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}