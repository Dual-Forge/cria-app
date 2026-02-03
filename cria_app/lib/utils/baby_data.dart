class BabyData {
  static const Map<int, Map<String, String>> weeklyData = {
    4: {'fruit': 'Semente de Papoula', 'size': '1 mm', 'weight': '< 1 g'},
    5: {'fruit': 'Semente de Gergelim', 'size': '2 mm', 'weight': '< 1 g'},
    6: {'fruit': 'Lentilha', 'size': '4 mm', 'weight': '< 1 g'},
    7: {'fruit': 'Mirtilo', 'size': '1.3 cm', 'weight': '< 1 g'},
    8: {'fruit': 'Framboesa', 'size': '1.6 cm', 'weight': '1 g'},
    9: {'fruit': 'Azeitona', 'size': '2.3 cm', 'weight': '2 g'},
    10: {'fruit': 'Ameixa Seca', 'size': '3.1 cm', 'weight': '4 g'},
    11: {'fruit': 'Limão', 'size': '4.1 cm', 'weight': '7 g'},
    12: {'fruit': 'Maracujá', 'size': '5.4 cm', 'weight': '14 g'},
    13: {'fruit': 'Pêssego', 'size': '7.4 cm', 'weight': '23 g'},
    14: {'fruit': 'Limão Siciliano', 'size': '8.7 cm', 'weight': '43 g'},
    15: {'fruit': 'Laranja', 'size': '10.1 cm', 'weight': '70 g'},
    16: {'fruit': 'Abacate', 'size': '11.6 cm', 'weight': '100 g'},
    17: {'fruit': 'Cebola', 'size': '13 cm', 'weight': '140 g'},
    18: {'fruit': 'Batata Doce', 'size': '14.2 cm', 'weight': '190 g'},
    19: {'fruit': 'Manga', 'size': '15.3 cm', 'weight': '240 g'},
    20: {'fruit': 'Banana', 'size': '16.4 cm', 'weight': '300 g'},
    21: {'fruit': 'Cenoura', 'size': '26.7 cm', 'weight': '360 g'},
    22: {'fruit': 'Mamão Papaya', 'size': '27.8 cm', 'weight': '430 g'},
    23: {'fruit': 'Toranja', 'size': '28.9 cm', 'weight': '501 g'},
    24: {'fruit': 'Espiga de Milho', 'size': '30 cm', 'weight': '600 g'},
    25: {'fruit': 'Rutabaga', 'size': '34.6 cm', 'weight': '660 g'},
    26: {'fruit': 'Cebolinha', 'size': '35.6 cm', 'weight': '760 g'},
    27: {'fruit': 'Couve-flor', 'size': '36.6 cm', 'weight': '875 g'},
    28: {'fruit': 'Beringela', 'size': '37.6 cm', 'weight': '1 kg'},
    29: {'fruit': 'Abóbora Bolota', 'size': '38.6 cm', 'weight': '1.1 kg'},
    30: {'fruit': 'Repolho', 'size': '39.9 cm', 'weight': '1.3 kg'},
    31: {'fruit': 'Coco', 'size': '41.1 cm', 'weight': '1.5 kg'},
    32: {'fruit': 'Couve Kale', 'size': '42.4 cm', 'weight': '1.7 kg'},
    33: {'fruit': 'Abacaxi', 'size': '43.7 cm', 'weight': '1.9 kg'},
    34: {'fruit': 'Melão Cantaloupe', 'size': '45 cm', 'weight': '2.1 kg'},
    35: {'fruit': 'Melão Honeydew', 'size': '46.2 cm', 'weight': '2.4 kg'},
    36: {'fruit': 'Alface Romana', 'size': '47.4 cm', 'weight': '2.6 kg'},
    37: {'fruit': 'Acelga', 'size': '48.6 cm', 'weight': '2.9 kg'},
    38: {'fruit': 'Alho Poró', 'size': '49.8 cm', 'weight': '3 kg'},
    39: {'fruit': 'Melancia Pequena', 'size': '50.7 cm', 'weight': '3.3 kg'},
    40: {'fruit': 'Abóbora Moranga', 'size': '51.2 cm', 'weight': '3.5 kg'},
    41: {'fruit': 'Jaca', 'size': '51.7 cm', 'weight': '3.7 kg'},
  };

  static Map<String, String> getData(int week) {
    if (week < 4) return {'fruit': 'Sementinha', 'size': 'Microscópico', 'weight': '-'};
    if (week > 41) return weeklyData[41]!;
    return weeklyData[week] ?? weeklyData[40]!;
  }
}