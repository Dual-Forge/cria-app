import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/utils/price_formatter.dart';

void main() {
  group('formatBRL', () {
    test('formata zero corretamente', () {
      expect(formatBRL(0), '0,00');
    });

    test('formata valor sem centavos', () {
      expect(formatBRL(100), '100,00');
    });

    test('formata valor com centavos', () {
      expect(formatBRL(6.5), '6,50');
    });

    test('formata valor grande sem pontuação de milhar', () {
      // toStringAsFixed não insere separador de milhar, apenas virgula decimal
      expect(formatBRL(1299.90), '1299,90');
    });

    test('arredonda corretamente para 2 casas decimais', () {
      expect(formatBRL(9.999), '10,00');
    });

    test('substitui ponto por vírgula', () {
      final result = formatBRL(3.14);
      expect(result.contains('.'), isFalse);
      expect(result.contains(','), isTrue);
    });
  });
}
