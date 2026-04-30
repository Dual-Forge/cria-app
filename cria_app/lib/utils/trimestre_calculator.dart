/// Trimestre Calculator
/// 
/// Calcula o progresso da gravidez por trimestre.
/// Retorna o trimestre atual, porcentagem de progresso e valor normalizado (0.0-1.0).

class TrimestreProgress {
  /// Nome do trimestre (ex: '1º Trimestre')
  final String name;

  /// Número do trimestre (1, 2 ou 3)
  final int number;

  /// Semana gestacional atual
  final int currentWeek;

  /// Semana inicial do trimestre
  final int startWeek;

  /// Semana final do trimestre
  final int endWeek;

  /// Progresso normalizado (0.0 - 1.0)
  final double progress;

  /// Porcentagem de progresso (0 - 100)
  final int percentage;

  TrimestreProgress({
    required this.name,
    required this.number,
    required this.currentWeek,
    required this.startWeek,
    required this.endWeek,
    required this.progress,
    required this.percentage,
  });

  @override
  String toString() => '$name - $percentage%';
}

/// Calcula a semana gestacional baseada na data da última menstruação (DUM)
/// 
/// Retorna um inteiro entre 0 e 42
int calculateGestationalWeek(DateTime? dumDate) {
  if (dumDate == null) return 0;

  final now = DateTime.now();
  final difference = now.difference(dumDate);
  int weeks = (difference.inDays / 7).floor();

  // Limitar entre 0 e 42 semanas
  return weeks > 42 ? 42 : (weeks < 0 ? 0 : weeks);
}

/// Calcula o progresso do trimestre atual
/// 
/// Retorna um objeto [TrimestreProgress] com informações completas
TrimestreProgress calculateTrimestreProgress(DateTime? dumDate) {
  final currentWeek = calculateGestationalWeek(dumDate);

  // Definir trimestres
  // 1º Trimestre: Semanas 1-13
  // 2º Trimestre: Semanas 14-27
  // 3º Trimestre: Semanas 28-40
  
  if (currentWeek <= 13) {
    // 1º Trimestre
    final progress = currentWeek / 13.0;
    return TrimestreProgress(
      name: '1º Trimestre',
      number: 1,
      currentWeek: currentWeek,
      startWeek: 1,
      endWeek: 13,
      progress: progress.clamp(0.0, 1.0),
      percentage: (progress * 100).toInt().clamp(0, 100),
    );
  } else if (currentWeek <= 27) {
    // 2º Trimestre
    final weeksInTrimestre = currentWeek - 13;
    final progress = weeksInTrimestre / 14.0;
    return TrimestreProgress(
      name: '2º Trimestre',
      number: 2,
      currentWeek: currentWeek,
      startWeek: 14,
      endWeek: 27,
      progress: progress.clamp(0.0, 1.0),
      percentage: (progress * 100).toInt().clamp(0, 100),
    );
  } else {
    // 3º Trimestre
    final weeksInTrimestre = currentWeek - 27;
    final progress = weeksInTrimestre / 13.0;
    return TrimestreProgress(
      name: '3º Trimestre',
      number: 3,
      currentWeek: currentWeek,
      startWeek: 28,
      endWeek: 40,
      progress: progress.clamp(0.0, 1.0),
      percentage: (progress * 100).toInt().clamp(0, 100),
    );
  }
}

/// Retorna uma descrição textual do trimestre
/// 
/// Exemplo: "Semana 15 de 14 (2º Trimestre)"
String getTrimestreDescription(DateTime? dumDate) {
  final progress = calculateTrimestreProgress(dumDate);
  final weeksInTrimestre = progress.currentWeek - progress.startWeek + 1;
  final totalWeeksInTrimestre = progress.endWeek - progress.startWeek + 1;
  
  return 'Semana $weeksInTrimestre de $totalWeeksInTrimestre (${progress.name})';
}

/// Retorna informações sobre o desenvolvimento do bebê no trimestre atual
String getTrimestreMilestone(DateTime? dumDate) {
  final progress = calculateTrimestreProgress(dumDate);

  switch (progress.number) {
    case 1:
      return 'Formação dos órgãos principais';
    case 2:
      return 'Crescimento rápido e movimentos';
    case 3:
      return 'Ganho de peso e preparação para o parto';
    default:
      return 'Gravidez em progresso';
  }
}

/// Retorna a cor recomendada para o trimestre
/// 
/// 1º Trimestre: Rosa claro
/// 2º Trimestre: Roxo claro
/// 3º Trimestre: Azul claro
String getTrimestreColorHex(DateTime? dumDate) {
  final progress = calculateTrimestreProgress(dumDate);

  switch (progress.number) {
    case 1:
      return '#FFB6C1'; // Rosa claro
    case 2:
      return '#DDA0DD'; // Roxo claro
    case 3:
      return '#ADD8E6'; // Azul claro
    default:
      return '#E0E0E0'; // Cinza
  }
}

/// Calcula quantas semanas faltam para o parto
/// 
/// Baseado em 40 semanas de gestação
int getWeeksRemaining(DateTime? dumDate) {
  final currentWeek = calculateGestationalWeek(dumDate);
  return (40 - currentWeek).clamp(0, 40);
}

/// Calcula a data estimada do parto (EDD)
/// 
/// Baseado em 280 dias (40 semanas) após a DUM
DateTime? getEstimatedDueDate(DateTime? dumDate) {
  if (dumDate == null) return null;
  return dumDate.add(const Duration(days: 280));
}

/// Calcula quantos dias faltam para o parto
int getDaysRemaining(DateTime? dumDate) {
  final edd = getEstimatedDueDate(dumDate);
  if (edd == null) return 0;

  final now = DateTime.now();
  final difference = edd.difference(now);
  return difference.inDays;
}

/// Retorna um resumo completo do progresso da gravidez
Map<String, dynamic> getPregnancySummary(DateTime? dumDate) {
  final progress = calculateTrimestreProgress(dumDate);
  final edd = getEstimatedDueDate(dumDate);
  final daysRemaining = getDaysRemaining(dumDate);
  final weeksRemaining = getWeeksRemaining(dumDate);

  return {
    'trimestre': progress.name,
    'numero_trimestre': progress.number,
    'semana_atual': progress.currentWeek,
    'progresso': progress.progress,
    'porcentagem': progress.percentage,
    'descricao': getTrimestreDescription(dumDate),
    'marco': getTrimestreMilestone(dumDate),
    'cor_hex': getTrimestreColorHex(dumDate),
    'data_prevista_parto': edd?.toIso8601String(),
    'dias_restantes': daysRemaining,
    'semanas_restantes': weeksRemaining,
  };
}
