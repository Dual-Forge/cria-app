import 'package:flutter/material.dart';
import '../../utils/trimestre_calculator.dart';

/// TrimestreProgressBar
/// 
/// Exibe a barra de progresso do trimestre com informações sobre o progresso da gravidez.
/// Integra a função de cálculo de trimestre com design Bento.
class TrimestreProgressBar extends StatelessWidget {
  /// Data da última menstruação (DUM) - nullable
  final DateTime? dumDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Altura da barra de progresso
  final double barHeight;

  /// Mostrar porcentagem
  final bool showPercentage;

  /// Mostrar nome do trimestre
  final bool showTrimestreName;

  /// Callback opcional quando a barra é clicada
  final VoidCallback? onTap;

  const TrimestreProgressBar({
    super.key,
    this.dumDate,
    required this.themeColor,
    this.barHeight = 8,
    this.showPercentage = true,
    this.showTrimestreName = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = calculateTrimestreProgress(dumDate);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com nome do trimestre e porcentagem
          if (showTrimestreName || showPercentage)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showTrimestreName)
                    Text(
                      progress.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: themeColor,
                      ),
                    ),
                  if (showPercentage)
                    Text(
                      '${progress.percentage}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                ],
              ),
            ),

          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(barHeight / 2),
            child: LinearProgressIndicator(
              value: progress.progress,
              minHeight: barHeight,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),

          // Informações adicionais
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Semana ${progress.currentWeek} de ${progress.endWeek}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// TrimestreProgressBarCompact
/// 
/// Versão compacta da barra de progresso do trimestre.
class TrimestreProgressBarCompact extends StatelessWidget {
  /// Data da última menstruação (DUM) - nullable
  final DateTime? dumDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Altura da barra de progresso
  final double barHeight;

  const TrimestreProgressBarCompact({
    super.key,
    this.dumDate,
    required this.themeColor,
    this.barHeight = 6,
  });

  @override
  Widget build(BuildContext context) {
    final progress = calculateTrimestreProgress(dumDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progress.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
            Text(
              '${progress.percentage}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: LinearProgressIndicator(
            value: progress.progress,
            minHeight: barHeight,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
        ),
      ],
    );
  }
}

/// TrimestreProgressBarDetailed
/// 
/// Versão detalhada com informações adicionais sobre o trimestre.
class TrimestreProgressBarDetailed extends StatelessWidget {
  /// Data da última menstruação (DUM) - nullable
  final DateTime? dumDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Altura da barra de progresso
  final double barHeight;

  /// Mostrar marco do desenvolvimento
  final bool showMilestone;

  /// Mostrar dias restantes
  final bool showDaysRemaining;

  const TrimestreProgressBarDetailed({
    super.key,
    this.dumDate,
    required this.themeColor,
    this.barHeight = 8,
    this.showMilestone = true,
    this.showDaysRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = calculateTrimestreProgress(dumDate);
    final daysRemaining = getDaysRemaining(dumDate);
    final milestone = getTrimestreMilestone(dumDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progress.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            Text(
              '${progress.percentage}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Barra de progresso
        ClipRRect(
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: LinearProgressIndicator(
            value: progress.progress,
            minHeight: barHeight,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
        ),
        const SizedBox(height: 8),

        // Informações adicionais
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semana ${progress.currentWeek} de ${progress.endWeek}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            if (showDaysRemaining)
              Text(
                '$daysRemaining dias restantes',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),

        // Marco do desenvolvimento
        if (showMilestone) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              milestone,
              style: TextStyle(
                fontSize: 11,
                color: themeColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// TrimestreProgressBarAnimated
/// 
/// Versão com animação ao carregar.
class TrimestreProgressBarAnimated extends StatefulWidget {
  /// Data da última menstruação (DUM) - nullable
  final DateTime? dumDate;

  /// Cor do tema para estilo
  final Color themeColor;

  /// Altura da barra de progresso
  final double barHeight;

  /// Duração da animação
  final Duration animationDuration;

  const TrimestreProgressBarAnimated({
    super.key,
    this.dumDate,
    required this.themeColor,
    this.barHeight = 8,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<TrimestreProgressBarAnimated> createState() =>
      _TrimestreProgressBarAnimatedState();
}

class _TrimestreProgressBarAnimatedState
    extends State<TrimestreProgressBarAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    final progress = calculateTrimestreProgress(widget.dumDate);

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: progress.progress)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    final progress = calculateTrimestreProgress(widget.dumDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progress.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.themeColor,
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColor,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.barHeight / 2),
              child: LinearProgressIndicator(
                value: _progressAnimation.value,
                minHeight: widget.barHeight,
                backgroundColor: Colors.grey[200],
                valueColor:
                    AlwaysStoppedAnimation<Color>(widget.themeColor),
              ),
            );
          },
        ),
      ],
    );
  }
}
