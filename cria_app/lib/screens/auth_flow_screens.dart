import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Verifica se existe uma sessão ativa
        final session = snapshot.data?.session;

        if (session != null) {
          // Se o usuário estiver logado, ele entra direto no App
          return const MainScreen();
        }

        // Se NÃO estiver logado, ele vê a sua nova tela de login estilizada
        return const LoginScreen();
      },
    );
  }
}
