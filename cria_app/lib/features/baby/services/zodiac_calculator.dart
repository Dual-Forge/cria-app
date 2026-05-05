/// Zodiac Calculator
/// 
/// Calcula o signo do zodíaco baseado em uma data.
/// Retorna o nome do signo e seu emoji correspondente.

class ZodiacSign {
  final String name;
  final String emoji;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  const ZodiacSign({
    required this.name,
    required this.emoji,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
  });
}

/// Lista de todos os signos do zodíaco em ordem
const List<ZodiacSign> _zodiacSigns = [
  ZodiacSign(
    name: 'Áries',
    emoji: '♈',
    startMonth: 3,
    startDay: 21,
    endMonth: 4,
    endDay: 19,
  ),
  ZodiacSign(
    name: 'Touro',
    emoji: '♉',
    startMonth: 4,
    startDay: 20,
    endMonth: 5,
    endDay: 20,
  ),
  ZodiacSign(
    name: 'Gêmeos',
    emoji: '♊',
    startMonth: 5,
    startDay: 21,
    endMonth: 6,
    endDay: 20,
  ),
  ZodiacSign(
    name: 'Câncer',
    emoji: '♋',
    startMonth: 6,
    startDay: 21,
    endMonth: 7,
    endDay: 22,
  ),
  ZodiacSign(
    name: 'Leão',
    emoji: '♌',
    startMonth: 7,
    startDay: 23,
    endMonth: 8,
    endDay: 22,
  ),
  ZodiacSign(
    name: 'Virgem',
    emoji: '♍',
    startMonth: 8,
    startDay: 23,
    endMonth: 9,
    endDay: 22,
  ),
  ZodiacSign(
    name: 'Libra',
    emoji: '♎',
    startMonth: 9,
    startDay: 23,
    endMonth: 10,
    endDay: 22,
  ),
  ZodiacSign(
    name: 'Escorpião',
    emoji: '♏',
    startMonth: 10,
    startDay: 23,
    endMonth: 11,
    endDay: 21,
  ),
  ZodiacSign(
    name: 'Sagitário',
    emoji: '♐',
    startMonth: 11,
    startDay: 22,
    endMonth: 12,
    endDay: 21,
  ),
  ZodiacSign(
    name: 'Capricórnio',
    emoji: '♑',
    startMonth: 12,
    startDay: 22,
    endMonth: 1,
    endDay: 19,
  ),
  ZodiacSign(
    name: 'Aquário',
    emoji: '♒',
    startMonth: 1,
    startDay: 20,
    endMonth: 2,
    endDay: 18,
  ),
  ZodiacSign(
    name: 'Peixes',
    emoji: '♓',
    startMonth: 2,
    startDay: 19,
    endMonth: 3,
    endDay: 20,
  ),
];

/// Calcula o signo do zodíaco para uma data específica
/// 
/// Retorna um mapa com:
/// - 'sign': Nome do signo (ex: 'Áries')
/// - 'emoji': Emoji do signo (ex: '♈')
/// 
/// Se a data for nula, retorna 'N/A' para ambos
Map<String, String> getZodiacSign(DateTime? date) {
  if (date == null) {
    return {'sign': 'N/A', 'emoji': '♈'};
  }

  final month = date.month;
  final day = date.day;

  // Procurar o signo correspondente
  for (final sign in _zodiacSigns) {
    if (_isDateInRange(month, day, sign)) {
      return {'sign': sign.name, 'emoji': sign.emoji};
    }
  }

  // Fallback (não deve acontecer)
  return {'sign': 'N/A', 'emoji': '♈'};
}

/// Verifica se uma data (mês/dia) está dentro do intervalo de um signo
/// 
/// Trata casos especiais como Capricórnio (22/12 - 19/01)
bool _isDateInRange(int month, int day, ZodiacSign sign) {
  // Caso especial: signos que atravessam o ano (ex: Capricórnio)
  if (sign.startMonth > sign.endMonth) {
    return (month == sign.startMonth && day >= sign.startDay) ||
        (month == sign.endMonth && day <= sign.endDay);
  }

  // Caso normal: signo dentro do mesmo ano
  if (month < sign.startMonth || month > sign.endMonth) {
    return false;
  }

  if (month == sign.startMonth && day < sign.startDay) {
    return false;
  }

  if (month == sign.endMonth && day > sign.endDay) {
    return false;
  }

  return true;
}

/// Retorna todos os signos do zodíaco
List<ZodiacSign> getAllZodiacSigns() => _zodiacSigns;

/// Retorna o signo anterior (cíclico)
ZodiacSign getPreviousZodiacSign(ZodiacSign sign) {
  final index = _zodiacSigns.indexOf(sign);
  if (index == -1) return _zodiacSigns.first;
  return _zodiacSigns[(index - 1) % _zodiacSigns.length];
}

/// Retorna o próximo signo (cíclico)
ZodiacSign getNextZodiacSign(ZodiacSign sign) {
  final index = _zodiacSigns.indexOf(sign);
  if (index == -1) return _zodiacSigns.first;
  return _zodiacSigns[(index + 1) % _zodiacSigns.length];
}
