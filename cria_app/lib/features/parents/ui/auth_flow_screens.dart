import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'profile_setup_screen.dart'; // Certifique-se de que esta tela existe
import '../../splash/ui/splash_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // 1. Se NÃO está logado, vai para o Login
        if (session == null) {
          return const LoginScreen();
        }

        // 2. Se ESTÁ logado, precisamos checar se o perfil existe no banco
        return FutureBuilder(
          future: Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', session.user.id)
              .maybeSingle(),
          builder: (context, profileSnapshot) {
            // Enquanto checa o banco, mostra um carregamento
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Text(
                      "Erro ao carregar perfil: ${profileSnapshot.error}",
                    ),
                  ),
                ),
              );
            }

            // 3. Se logou mas NÃO tem perfil (banco limpo), vai para Setup
            if (profileSnapshot.data == null) {
              return const ProfileSetupScreen();
            }

            // 4. Se logou e JÁ TEM perfil, vai para a SplashScreen
            return const SplashScreen();
          },
        );
      },
    );
  }
}
