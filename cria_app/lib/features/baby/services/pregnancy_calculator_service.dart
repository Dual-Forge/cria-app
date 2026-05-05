/// PregnancyCalculatorService
///
/// Fonte única de verdade para todos os cálculos gestacionais do app.
/// Substitui lógica duplicada em: settings_screen, chatbot_screen,
/// baby_details_screen e baby_card_widget.
///
/// Absorve e expande o trimestre_calculator.dart original.
library;

import 'package:cria_app/features/baby/services/zodiac_calculator.dart';



class GestationalInfo {
  final int weeks;
  final int days;
  final int trimester;
  final String trimesterName;
  final double trimesterProgress;
  final DateTime? estimatedDueDate;
  final int daysRemaining;
  final int weeksRemaining;
  final String zodiacSign;

  const GestationalInfo({
    required this.weeks,
    required this.days,
    required this.trimester,
    required this.trimesterName,
    required this.trimesterProgress,
    required this.estimatedDueDate,
    required this.daysRemaining,
    required this.weeksRemaining,
    required this.zodiacSign,
  });

  String get summary => '$weeks semanas + $days dias';
}

// ── Serviço ───────────────────────────────────────────────────────────────────

class PregnancyCalculatorService {
  const PregnancyCalculatorService._();

  /// Calcula todas as informações gestacionais a partir da DUM.
  static GestationalInfo calculate(DateTime? dumDate) {
    if (dumDate == null) {
      return const GestationalInfo(
        weeks: 0,
        days: 0,
        trimester: 1,
        trimesterName: '1º Trimestre',
        trimesterProgress: 0,
        estimatedDueDate: null,
        daysRemaining: 280,
        weeksRemaining: 40,
        zodiacSign: '',
      );
    }

    final now = DateTime.now();
    final totalDays = now.difference(dumDate).inDays.clamp(0, 294);
    final weeks = totalDays ~/ 7;
    final days = totalDays % 7;
    final clampedWeeks = weeks.clamp(0, 42);

    final edd = dumDate.add(const Duration(days: 280));
    final daysRemaining = edd.difference(now).inDays.clamp(0, 280);
    final weeksRemaining = (daysRemaining / 7).ceil().clamp(0, 40);

    final (trimester, trimesterName, progress) = _trimesterInfo(clampedWeeks);

    final zodiacResult = getZodiacSign(edd);
    final zodiac = '${zodiacResult['emoji']} ${zodiacResult['sign']}';

    return GestationalInfo(
      weeks: clampedWeeks,
      days: days,
      trimester: trimester,
      trimesterName: trimesterName,
      trimesterProgress: progress,
      estimatedDueDate: edd,
      daysRemaining: daysRemaining,
      weeksRemaining: weeksRemaining,
      zodiacSign: zodiac,
    );
  }

  /// Retorna apenas a semana gestacional (atalho para uso simples).
  static int weekFromDum(DateTime? dumDate) {
    if (dumDate == null) return 0;
    final days = DateTime.now().difference(dumDate).inDays;
    return (days ~/ 7).clamp(0, 42);
  }

  /// Retorna semanas e dias restantes a partir da due date (lógica inversa).
  static ({int weeks, int days}) fromDueDate(DateTime? dueDate) {
    if (dueDate == null) return (weeks: 40, days: 0);
    final now = DateTime.now();
    final totalDays = dueDate.difference(now).inDays.clamp(0, 280);
    return (weeks: 40 - (totalDays ~/ 7), days: totalDays % 7);
  }

  // ── Privados ────────────────────────────────────────────────────────────────

  static (int, String, double) _trimesterInfo(int week) {
    if (week <= 13) {
      return (1, '1º Trimestre', (week / 13.0).clamp(0.0, 1.0));
    } else if (week <= 27) {
      return (2, '2º Trimestre', ((week - 13) / 14.0).clamp(0.0, 1.0));
    } else {
      return (3, '3º Trimestre', ((week - 27) / 13.0).clamp(0.0, 1.0));
    }
  }
}
