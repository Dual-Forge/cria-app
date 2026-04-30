import 'package:flutter/material.dart';
import '../../utils/zodiac_calculator.dart';

/// ZodiacBadgeWidget
/// 
/// Exibe o signo do zodíaco previsto para o bebê em um Chip estilizado.
/// Integra a função de cálculo de zodíaco com design Bento.
class ZodiacBadgeWidget extends StatelessWidget {
  /// Data prevista do parto (nullable)
  final DateTime? expectedDueDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Tamanho do texto do emoji
  final double emojiSize;

  /// Tamanho do texto do signo
  final double textSize;

  /// Callback opcional quando o badge é clicado
  final VoidCallback? onTap;

  const ZodiacBadgeWidget({
    super.key,
    this.expectedDueDate,
    required this.themeColor,
    this.emojiSize = 20,
    this.textSize = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final zodiac = getZodiacSign(expectedDueDate);
    final sign = zodiac['sign'] ?? 'N/A';
    final emoji = zodiac['emoji'] ?? '♈';

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: emojiSize),
            ),
            const SizedBox(width: 6),
            Text(
              sign,
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ],
        ),
        backgroundColor: themeColor.withOpacity(0.1),
        side: BorderSide(
          color: themeColor.withOpacity(0.3),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// ZodiacBadgeContainerWidget
/// 
/// Versão estendida com Container customizável para mais controle de estilo.
class ZodiacBadgeContainerWidget extends StatelessWidget {
  /// Data prevista do parto (nullable)
  final DateTime? expectedDueDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Cor de fundo customizável
  final Color? backgroundColor;

  /// Cor da borda customizável
  final Color? borderColor;

  /// Raio dos cantos
  final double borderRadius;

  /// Padding interno
  final EdgeInsets padding;

  /// Tamanho do texto do emoji
  final double emojiSize;

  /// Tamanho do texto do signo
  final double textSize;

  /// Callback opcional quando o badge é clicado
  final VoidCallback? onTap;

  const ZodiacBadgeContainerWidget({
    super.key,
    this.expectedDueDate,
    required this.themeColor,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.emojiSize = 20,
    this.textSize = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final zodiac = getZodiacSign(expectedDueDate);
    final sign = zodiac['sign'] ?? 'N/A';
    final emoji = zodiac['emoji'] ?? '♈';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? themeColor.withOpacity(0.1),
          border: Border.all(
            color: borderColor ?? themeColor.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: emojiSize),
            ),
            const SizedBox(width: 6),
            Text(
              sign,
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ZodiacBadgeDetailedWidget
/// 
/// Versão com informações adicionais sobre o signo.
class ZodiacBadgeDetailedWidget extends StatelessWidget {
  /// Data prevista do parto (nullable)
  final DateTime? expectedDueDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Mostrar data prevista do parto
  final bool showDueDate;

  /// Callback opcional quando o badge é clicado
  final VoidCallback? onTap;

  const ZodiacBadgeDetailedWidget({
    super.key,
    this.expectedDueDate,
    required this.themeColor,
    this.showDueDate = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final zodiac = getZodiacSign(expectedDueDate);
    final sign = zodiac['sign'] ?? 'N/A';
    final emoji = zodiac['emoji'] ?? '♈';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.08),
          border: Border.all(
            color: themeColor.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  sign,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
            if (showDueDate && expectedDueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(expectedDueDate!),
                style: TextStyle(
                  fontSize: 11,
                  color: themeColor.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formata a data para exibição
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// ZodiacBadgeAnimatedWidget
/// 
/// Versão com animação ao carregar.
class ZodiacBadgeAnimatedWidget extends StatefulWidget {
  /// Data prevista do parto (nullable)
  final DateTime? expectedDueDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Duração da animação
  final Duration animationDuration;

  /// Callback opcional quando o badge é clicado
  final VoidCallback? onTap;

  const ZodiacBadgeAnimatedWidget({
    super.key,
    this.expectedDueDate,
    required this.themeColor,
    this.animationDuration = const Duration(milliseconds: 500),
    this.onTap,
  });

  @override
  State<ZodiacBadgeAnimatedWidget> createState() =>
      _ZodiacBadgeAnimatedWidgetState();
}

class _ZodiacBadgeAnimatedWidgetState extends State<ZodiacBadgeAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ZodiacBadgeContainerWidget(
          expectedDueDate: widget.expectedDueDate,
          themeColor: widget.themeColor,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
