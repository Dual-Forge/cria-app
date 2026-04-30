import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/utils/trimestre_calculator.dart';

void main() {
  group('Trimestre Calculator Tests', () {
    group('calculateGestationalWeek', () {
      test('retorna 0 para data nula', () {
        final weeks = calculateGestationalWeek(null);
        expect(weeks, equals(0));
      });

      test('retorna 0 para data futura', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final weeks = calculateGestationalWeek(futureDate);
        expect(weeks, equals(0));
      });

      test('retorna semana correta para data passada', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 70));
        final weeks = calculateGestationalWeek(dumDate);
        expect(weeks, equals(10)); // 70 dias / 7 = 10 semanas
      });

      test('limita máximo em 42 semanas', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 400));
        final weeks = calculateGestationalWeek(dumDate);
        expect(weeks, equals(42));
      });

      test('calcula corretamente para 13 semanas', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 91));
        final weeks = calculateGestationalWeek(dumDate);
        expect(weeks, equals(13));
      });

      test('calcula corretamente para 27 semanas', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 189));
        final weeks = calculateGestationalWeek(dumDate);
        expect(weeks, equals(27));
      });

      test('calcula corretamente para 40 semanas', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 280));
        final weeks = calculateGestationalWeek(dumDate);
        expect(weeks, equals(40));
      });
    });

    group('calculateTrimestreProgress', () {
      test('retorna 1º Trimestre para semana 1', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 7));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.name, equals('1º Trimestre'));
        expect(progress.number, equals(1));
      });

      test('retorna 1º Trimestre para semana 13', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 91));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.name, equals('1º Trimestre'));
        expect(progress.number, equals(1));
      });

      test('retorna 2º Trimestre para semana 14', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 98));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.name, equals('2º Trimestre'));
        expect(progress.number, equals(2));
      });

      test('retorna 2º Trimestre para semana 27', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 189));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.name, equals('2º Trimestre'));
        expect(progress.number, equals(2));
      });

      test('retorna 3º Trimestre para semana 28', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 196));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.name, equals('3º Trimestre'));
        expect(progress.number, equals(3));
      });

      test('retorna 3º Trimestre para semana 40', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 280));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.name, equals('3º Trimestre'));
        expect(progress.number, equals(3));
      });

      test('calcula progresso correto para 1º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 49)); // 7 semanas
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.progress, closeTo(7 / 13, 0.01));
        expect(progress.percentage, equals(53)); // (7/13)*100 ≈ 53%
      });

      test('calcula progresso correto para 2º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 140)); // 20 semanas
        final progress = calculateTrimestreProgress(dumDate);
        final expectedProgress = (20 - 13) / 14.0; // 7 semanas de 14
        expect(progress.progress, closeTo(expectedProgress, 0.01));
      });

      test('calcula progresso correto para 3º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 245)); // 35 semanas
        final progress = calculateTrimestreProgress(dumDate);
        final expectedProgress = (35 - 27) / 13.0; // 8 semanas de 13
        expect(progress.progress, closeTo(expectedProgress, 0.01));
      });

      test('progresso é limitado entre 0.0 e 1.0', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 400)); // > 42 semanas
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.progress, lessThanOrEqualTo(1.0));
        expect(progress.progress, greaterThanOrEqualTo(0.0));
      });

      test('porcentagem é limitada entre 0 e 100', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 400));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.percentage, lessThanOrEqualTo(100));
        expect(progress.percentage, greaterThanOrEqualTo(0));
      });

      test('retorna dados corretos para data nula', () {
        final progress = calculateTrimestreProgress(null);
        expect(progress.name, equals('1º Trimestre'));
        expect(progress.currentWeek, equals(0));
        expect(progress.progress, equals(0.0));
        expect(progress.percentage, equals(0));
      });
    });

    group('getTrimestreDescription', () {
      test('retorna descrição correta para 1º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 49)); // 7 semanas
        final description = getTrimestreDescription(dumDate);
        expect(description, contains('1º Trimestre'));
      });

      test('retorna descrição correta para 2º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 140)); // 20 semanas
        final description = getTrimestreDescription(dumDate);
        expect(description, contains('2º Trimestre'));
      });

      test('retorna descrição correta para 3º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 245)); // 35 semanas
        final description = getTrimestreDescription(dumDate);
        expect(description, contains('3º Trimestre'));
      });
    });

    group('getTrimestreMilestone', () {
      test('retorna marco correto para 1º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 49));
        final milestone = getTrimestreMilestone(dumDate);
        expect(milestone, equals('Formação dos órgãos principais'));
      });

      test('retorna marco correto para 2º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 140));
        final milestone = getTrimestreMilestone(dumDate);
        expect(milestone, equals('Crescimento rápido e movimentos'));
      });

      test('retorna marco correto para 3º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 245));
        final milestone = getTrimestreMilestone(dumDate);
        expect(milestone, equals('Ganho de peso e preparação para o parto'));
      });
    });

    group('getTrimestreColorHex', () {
      test('retorna cor rosa para 1º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 49));
        final color = getTrimestreColorHex(dumDate);
        expect(color, equals('#FFB6C1'));
      });

      test('retorna cor roxa para 2º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 140));
        final color = getTrimestreColorHex(dumDate);
        expect(color, equals('#DDA0DD'));
      });

      test('retorna cor azul para 3º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 245));
        final color = getTrimestreColorHex(dumDate);
        expect(color, equals('#ADD8E6'));
      });
    });

    group('getWeeksRemaining', () {
      test('retorna 40 semanas para data nula', () {
        final weeks = getWeeksRemaining(null);
        expect(weeks, equals(40));
      });

      test('retorna 33 semanas para 7 semanas de gestação', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 49));
        final weeks = getWeeksRemaining(dumDate);
        expect(weeks, equals(33));
      });

      test('retorna 0 semanas para 40 semanas de gestação', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 280));
        final weeks = getWeeksRemaining(dumDate);
        expect(weeks, equals(0));
      });

      test('retorna 0 para mais de 40 semanas', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 400));
        final weeks = getWeeksRemaining(dumDate);
        expect(weeks, equals(0));
      });
    });

    group('getEstimatedDueDate', () {
      test('retorna nula para data nula', () {
        final edd = getEstimatedDueDate(null);
        expect(edd, isNull);
      });

      test('retorna data 280 dias após DUM', () {
        final dumDate = DateTime(2026, 1, 1);
        final edd = getEstimatedDueDate(dumDate);
        expect(edd, equals(DateTime(2026, 10, 8))); // 280 dias depois
      });
    });

    group('getDaysRemaining', () {
      test('retorna 0 para data nula', () {
        final days = getDaysRemaining(null);
        expect(days, equals(0));
      });

      test('retorna dias positivos para gravidez em andamento', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 100));
        final days = getDaysRemaining(dumDate);
        expect(days, greaterThan(0));
      });
    });

    group('getPregnancySummary', () {
      test('retorna mapa com todas as chaves necessárias', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 140));
        final summary = getPregnancySummary(dumDate);

        expect(summary.containsKey('trimestre'), isTrue);
        expect(summary.containsKey('numero_trimestre'), isTrue);
        expect(summary.containsKey('semana_atual'), isTrue);
        expect(summary.containsKey('progresso'), isTrue);
        expect(summary.containsKey('porcentagem'), isTrue);
        expect(summary.containsKey('descricao'), isTrue);
        expect(summary.containsKey('marco'), isTrue);
        expect(summary.containsKey('cor_hex'), isTrue);
        expect(summary.containsKey('data_prevista_parto'), isTrue);
        expect(summary.containsKey('dias_restantes'), isTrue);
        expect(summary.containsKey('semanas_restantes'), isTrue);
      });

      test('retorna dados corretos para 2º Trimestre', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 140));
        final summary = getPregnancySummary(dumDate);

        expect(summary['numero_trimestre'], equals(2));
        expect(summary['trimestre'], equals('2º Trimestre'));
        expect(summary['marco'], equals('Crescimento rápido e movimentos'));
        expect(summary['cor_hex'], equals('#DDA0DD'));
      });
    });

    group('Edge cases', () {
      test('calcula corretamente para limite entre trimestres (semana 13)', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 91));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.number, equals(1));
      });

      test('calcula corretamente para limite entre trimestres (semana 14)', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 98));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.number, equals(2));
      });

      test('calcula corretamente para limite entre trimestres (semana 27)', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 189));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.number, equals(2));
      });

      test('calcula corretamente para limite entre trimestres (semana 28)', () {
        final dumDate = DateTime.now().subtract(const Duration(days: 196));
        final progress = calculateTrimestreProgress(dumDate);
        expect(progress.number, equals(3));
      });
    });
  });
}
