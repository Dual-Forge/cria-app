import 'package:cria_app/features/baby/services/pregnancy_calculator_service.dart';

/// Funções utilitárias legadas para cálculos gestacionais.
/// Fornecem compatibilidade com testes e código antigo, usando o
/// PregnancyCalculatorService internamente.

int calculateGestationalWeek(DateTime? dumDate) {
  return PregnancyCalculatorService.weekFromDum(dumDate);
}

class TrimestreProgress {
  final int number;
  final String name;
  final double progress;
  final int percentage;
  final int currentWeek;

  int get endWeek => number == 1 ? 13 : (number == 2 ? 27 : 42);

  TrimestreProgress({
    required this.number,
    required this.name,
    required this.progress,
    required this.percentage,
    required this.currentWeek,
  });
}

TrimestreProgress calculateTrimestreProgress(DateTime? dumDate) {
  final info = PregnancyCalculatorService.calculate(dumDate);
  return TrimestreProgress(
    number: info.trimester,
    name: info.trimesterName,
    progress: info.trimesterProgress,
    percentage: (info.trimesterProgress * 100).round(),
    currentWeek: info.weeks,
  );
}

String getTrimestreDescription(DateTime? dumDate) {
  final info = PregnancyCalculatorService.calculate(dumDate);
  return 'Você está no ${info.trimesterName} (${info.weeks} semanas).';
}

String getTrimestreMilestone(DateTime? dumDate) {
  final week = PregnancyCalculatorService.weekFromDum(dumDate);
  if (week <= 13) return 'Formação dos órgãos principais';
  if (week <= 27) return 'Crescimento rápido e movimentos';
  return 'Ganho de peso e preparação para o parto';
}

String getTrimestreColorHex(DateTime? dumDate) {
  final week = PregnancyCalculatorService.weekFromDum(dumDate);
  if (week <= 13) return '#FFB6C1';
  if (week <= 27) return '#DDA0DD';
  return '#ADD8E6';
}

int getWeeksRemaining(DateTime? dumDate) {
  return PregnancyCalculatorService.calculate(dumDate).weeksRemaining;
}

DateTime? getEstimatedDueDate(DateTime? dumDate) {
  return PregnancyCalculatorService.calculate(dumDate).estimatedDueDate;
}

int getDaysRemaining(DateTime? dumDate) {
  return PregnancyCalculatorService.calculate(dumDate).daysRemaining;
}

Map<String, dynamic> getPregnancySummary(DateTime? dumDate) {
  final info = PregnancyCalculatorService.calculate(dumDate);
  return {
    'trimestre': info.trimesterName,
    'numero_trimestre': info.trimester,
    'semana_atual': info.weeks,
    'progresso': info.trimesterProgress,
    'porcentagem': (info.trimesterProgress * 100).round(),
    'descricao': getTrimestreDescription(dumDate),
    'marco': getTrimestreMilestone(dumDate),
    'cor_hex': getTrimestreColorHex(dumDate),
    'data_prevista_parto': info.estimatedDueDate,
    'dias_restantes': info.daysRemaining,
    'semanas_restantes': info.weeksRemaining,
  };
}

/// Calcula a DPP (Data Provável do Parto) baseada na Regra de Naegele.
DateTime calculateDPP(DateTime dum) {
  return dum.add(const Duration(days: 280));
}

/// Determina o signo zodiacal com base na data da DPP.
Map<String, String> getZodiacSign(DateTime date) {
  int day = date.day;
  int month = date.month;

  if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return {'name': 'Áries', 'emoji': '♈'};
  if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return {'name': 'Touro', 'emoji': '♉'};
  if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return {'name': 'Gêmeos', 'emoji': '♊'};
  if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return {'name': 'Câncer', 'emoji': '♋'};
  if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return {'name': 'Leão', 'emoji': '♌'};
  if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return {'name': 'Virgem', 'emoji': '♍'};
  if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return {'name': 'Libra', 'emoji': '♎'};
  if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return {'name': 'Escorpião', 'emoji': '♏'};
  if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return {'name': 'Sagitário', 'emoji': '♐'};
  if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return {'name': 'Capricórnio', 'emoji': '♑'};
  if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return {'name': 'Aquário', 'emoji': '♒'};
  return {'name': 'Peixes', 'emoji': '♓'};
}

