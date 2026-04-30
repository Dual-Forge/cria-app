import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ================= DESIGN TOKENS =================
/// Tokens centralizados do design do app.
/// Importado por qualquer tela que precise das cores ou estilos base.

class AppColors {
  static const bgTop = Color(0xFFFDE7F2);
  static const bgBottom = Color(0xFFBFE7FF);

  static const primaryPink = Color(0xFFE66C73);
  static const primaryPurple = Color(0xFF7C52AA);

  static const fieldFill = Color(0xFFF3F4F6);
  static const textMuted = Color(0xFF6B7280);
}

class AppStyles {
  static BorderRadius pill = BorderRadius.circular(999);
  static BorderRadius card = BorderRadius.circular(30);

  static BoxShadow softShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 25,
    offset: const Offset(0, 12),
  );
}

/// ================= GLOBAL BACKGROUND WRAPPER =================
///
/// Renderiza o fundo animado UMA única vez por trás de toda a navegação.
/// Aplicado no `builder` do MaterialApp.router.
///
/// CORREÇÕES WEB:
/// - Envolto em `Scaffold` com `backgroundColor: transparent` para garantir
///   que haja um ancestral `Material` válido (obrigatório no Flutter Web).
/// - `child` recebe fallback `SizedBox.shrink()` para evitar null crash
///   durante a inicialização do GoRouter.
/// - O background usa `SizedBox.expand()` em vez de `Container` sem tamanho
///   para forçar constraints explícitas no Web.
/// - `_FloatingStars` usa `LayoutBuilder` para garantir que os `Positioned`
///   tenham um pai com tamanho definido.

class GlobalBackgroundWrapper extends StatelessWidget {
  final Widget? child;

  const GlobalBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // O Scaffold aqui serve como "container de raiz" que:
    // 1. Fornece um ancestral Material válido para a árvore toda
    // 2. Garante que o Stack filho tenha constraints de tela cheia
    // 3. Mantém o background fixo enquanto o conteúdo navega
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand, // força o Stack a ocupar 100% da tela
        children: [
          // Camada 1: fundo global — sempre por baixo de tudo
          const _AppBackground(),

          // Camada 2: conteúdo da rota atual
          // child pode ser null durante a inicialização do GoRouter no Web
          child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// ───────────────────────────────────────────────
/// Background: gradiente + onda + estrelas
/// ───────────────────────────────────────────────

class _AppBackground extends StatelessWidget {
  const _AppBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradiente base
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bgTop, AppColors.bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // Onda decorativa
          const CustomPaint(painter: _WavePainter()),

          // Estrelas flutuantes — desabilitadas no Web para evitar
          // overhead de animação desnecessário e possíveis falhas de vsync
          if (!kIsWeb) const _FloatingStars(),
        ],
      ),
    );
  }
}

/// ───────────────────────────────────────────────
/// Onda (CustomPainter — funciona igual em Web e Mobile)
/// ───────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Proteção: não renderiza se o size não foi resolvido
    if (size.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFBFE7FF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.65,
        size.width * 0.5,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.85,
        size.width,
        size.height * 0.75,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}

/// ───────────────────────────────────────────────
/// Estrelas flutuantes (Mobile only)
/// ───────────────────────────────────────────────

class _FloatingStars extends StatefulWidget {
  const _FloatingStars();

  @override
  State<_FloatingStars> createState() => _FloatingStarsState();
}

class _FloatingStarsState extends State<_FloatingStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState(); // SEMPRE primeiro
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder garante que os Positioned tenham um pai com size definido
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, _x) {
            return Stack(
              children: List.generate(8, (i) {
                final offset = sin((_controller.value + i) * pi) * 10;
                return Positioned(
                  top: 80.0 + (i * 60) + offset,
                  left: (i % 2 == 0) ? 40.0 : null,
                  right: (i % 2 != 0) ? 40.0 : null,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14.0 + (i % 3 * 6).toDouble(),
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
