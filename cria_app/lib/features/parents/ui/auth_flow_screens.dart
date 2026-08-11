import 'package:flutter/material.dart';

/// Tela de carregamento exibida na rota '/' enquanto o GoRouter
/// avalia o redirect de autenticação. Deve ser minimalista.
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Transparente para deixar o GlobalBackgroundWrapper aparecer.
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C52AA)),
        ),
      ),
    );
  }
}
