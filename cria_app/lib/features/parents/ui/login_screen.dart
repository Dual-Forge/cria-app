import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cria_app/app/app_dependencies.dart';
import 'package:cria_app/widgets/app_background.dart';

// AppColors e AppStyles são importados de app_background.dart

/// ================= COMPONENTS =================

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: AppStyles.card,
        boxShadow: [AppStyles.softShadow],
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB199), Color(0xFFE66C73)],
          ),
          borderRadius: AppStyles.pill,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Entrar",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleLoginButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyles.pill,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
              height: 24,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, size: 30),
            ),
            const SizedBox(width: 12),
            const Text(
              "Continuar com Google",
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;

  const SoftTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryPurple),
        filled: true,
        fillColor: AppColors.fieldFill,
        border: OutlineInputBorder(
          borderRadius: AppStyles.pill,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// ================= LOGIN SCREEN =================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;

  late AnimationController _fadeController;

  @override
  void initState() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    super.initState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AppDependencies.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await AppDependencies.client.auth.signUp(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // Google BLOQUEIA autenticação em WebViews embutidos.
      // É OBRIGATÓRIO usar o browser externo (Chrome) com externalApplication.
      // O Supabase SDK (v2) captura automaticamente o deep link quando o app
      // retorna, desde que o AndroidManifest tenha o intent-filter correto.
      await AppDependencies.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? (Uri.base.origin.contains('localhost') ? Uri.base.origin : 'https://denguinho-mu.vercel.app/')
            : 'io.supabase.flutter://login-callback/',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro Google: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O background global é renderizado pelo GlobalBackgroundWrapper no main.dart.
      // O Scaffold precisa ser transparente para que o fundo apareça.
      backgroundColor: Colors.transparent,
      // Evita que o Scaffold (e portanto o background global) encolha quando
      // o teclado abre. O conteúdo interno rola normalmente.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeController,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),

                      const Text(
                        "Cria",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),

                      const SizedBox(height: 20),

                      GlassCard(
                        child: Column(
                          children: [
                            SoftTextField(
                              controller: _emailController,
                              label: "E-mail",
                              icon: Icons.mail,
                            ),
                            const SizedBox(height: 16),
                            SoftTextField(
                              controller: _passwordController,
                              label: "Senha",
                              icon: Icons.lock,
                              isPassword: true,
                            ),
                            const SizedBox(height: 20),

                            _isLoading
                                ? const CircularProgressIndicator()
                                : Column(
                                    children: [
                                      GradientButton(
                                        text: "Entrar",
                                        onPressed: _authenticate,
                                      ),
                                      const SizedBox(height: 24),
                                      const Row(
                                        children: [
                                          Expanded(child: Divider()),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text(
                                              "OU",
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(child: Divider()),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      GoogleLoginButton(
                                        onPressed: _signInWithGoogle,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
