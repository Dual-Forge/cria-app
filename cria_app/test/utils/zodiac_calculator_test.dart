import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/features/baby/services/zodiac_calculator.dart';

void main() {
  group('Zodiac Calculator Tests', () {
    group('getZodiacSign', () {
      test('retorna Áries para 21 de março', () {
        final date = DateTime(2026, 3, 21);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Áries'));
        expect(result['emoji'], equals('♈'));
      });

      test('retorna Áries para 19 de abril', () {
        final date = DateTime(2026, 4, 19);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Áries'));
        expect(result['emoji'], equals('♈'));
      });

      test('retorna Touro para 20 de abril', () {
        final date = DateTime(2026, 4, 20);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Touro'));
        expect(result['emoji'], equals('♉'));
      });

      test('retorna Touro para 20 de maio', () {
        final date = DateTime(2026, 5, 20);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Touro'));
        expect(result['emoji'], equals('♉'));
      });

      test('retorna Gêmeos para 21 de maio', () {
        final date = DateTime(2026, 5, 21);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Gêmeos'));
        expect(result['emoji'], equals('♊'));
      });

      test('retorna Câncer para 21 de junho', () {
        final date = DateTime(2026, 6, 21);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Câncer'));
        expect(result['emoji'], equals('♋'));
      });

      test('retorna Leão para 23 de julho', () {
        final date = DateTime(2026, 7, 23);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Leão'));
        expect(result['emoji'], equals('♌'));
      });

      test('retorna Virgem para 23 de agosto', () {
        final date = DateTime(2026, 8, 23);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Virgem'));
        expect(result['emoji'], equals('♍'));
      });

      test('retorna Libra para 23 de setembro', () {
        final date = DateTime(2026, 9, 23);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Libra'));
        expect(result['emoji'], equals('♎'));
      });

      test('retorna Escorpião para 23 de outubro', () {
        final date = DateTime(2026, 10, 23);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Escorpião'));
        expect(result['emoji'], equals('♏'));
      });

      test('retorna Sagitário para 22 de novembro', () {
        final date = DateTime(2026, 11, 22);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Sagitário'));
        expect(result['emoji'], equals('♐'));
      });

      test('retorna Capricórnio para 22 de dezembro', () {
        final date = DateTime(2026, 12, 22);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Capricórnio'));
        expect(result['emoji'], equals('♑'));
      });

      test('retorna Capricórnio para 19 de janeiro', () {
        final date = DateTime(2026, 1, 19);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Capricórnio'));
        expect(result['emoji'], equals('♑'));
      });

      test('retorna Aquário para 20 de janeiro', () {
        final date = DateTime(2026, 1, 20);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Aquário'));
        expect(result['emoji'], equals('♒'));
      });

      test('retorna Peixes para 19 de fevereiro', () {
        final date = DateTime(2026, 2, 19);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Peixes'));
        expect(result['emoji'], equals('♓'));
      });

      test('retorna N/A para data nula', () {
        final result = getZodiacSign(null);
        expect(result['sign'], equals('N/A'));
        expect(result['emoji'], equals('♈'));
      });

      test('retorna signo correto para 1º de janeiro', () {
        final date = DateTime(2026, 1, 1);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Capricórnio'));
      });

      test('retorna signo correto para 31 de dezembro', () {
        final date = DateTime(2026, 12, 31);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Capricórnio'));
      });
    });

    group('getAllZodiacSigns', () {
      test('retorna 12 signos', () {
        final signs = getAllZodiacSigns();
        expect(signs.length, equals(12));
      });

      test('primeiro signo é Áries', () {
        final signs = getAllZodiacSigns();
        expect(signs.first.name, equals('Áries'));
      });

      test('último signo é Peixes', () {
        final signs = getAllZodiacSigns();
        expect(signs.last.name, equals('Peixes'));
      });
    });

    group('getPreviousZodiacSign', () {
      test('retorna Peixes para Áries', () {
        final aries = getAllZodiacSigns().first;
        final previous = getPreviousZodiacSign(aries);
        expect(previous.name, equals('Peixes'));
      });

      test('retorna Áries para Touro', () {
        final taurus = getAllZodiacSigns()[1];
        final previous = getPreviousZodiacSign(taurus);
        expect(previous.name, equals('Áries'));
      });
    });

    group('getNextZodiacSign', () {
      test('retorna Touro para Áries', () {
        final aries = getAllZodiacSigns().first;
        final next = getNextZodiacSign(aries);
        expect(next.name, equals('Touro'));
      });

      test('retorna Áries para Peixes', () {
        final pisces = getAllZodiacSigns().last;
        final next = getNextZodiacSign(pisces);
        expect(next.name, equals('Áries'));
      });
    });

    group('Edge cases', () {
      test('data no limite entre signos (20 de abril)', () {
        final date = DateTime(2026, 4, 20);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Touro'));
      });

      test('data no limite entre signos (19 de abril)', () {
        final date = DateTime(2026, 4, 19);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Áries'));
      });

      test('Capricórnio atravessa o ano (22 de dezembro)', () {
        final date = DateTime(2026, 12, 22);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Capricórnio'));
      });

      test('Capricórnio atravessa o ano (1º de janeiro)', () {
        final date = DateTime(2026, 1, 1);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Capricórnio'));
      });

      test('Capricórnio não inclui 20 de janeiro', () {
        final date = DateTime(2026, 1, 20);
        final result = getZodiacSign(date);
        expect(result['sign'], equals('Aquário'));
      });
    });
  });
}
