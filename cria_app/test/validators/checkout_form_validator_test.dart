import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

// Ajuste o import abaixo para o caminho correto do seu projeto, se necessário
import 'package:cria_app/validators/checkout_form_validator.dart';

void main() {
  group('Task 6.2: CheckoutFormValidator Unit Tests', () {
    test('validateName: rejeita vazio e menor que 3 chars', () {
      expect(CheckoutFormValidator.validateName(''), 'Nome é obrigatório');
      expect(CheckoutFormValidator.validateName('   '), 'Nome é obrigatório');
      expect(CheckoutFormValidator.validateName('Zé'), 'Nome inválido (mínimo 3 caracteres)');
      expect(CheckoutFormValidator.validateName('João'), isNull);
    });

    test('validatePhone: formata e rejeita tamanhos inválidos', () {
      expect(CheckoutFormValidator.validatePhone(''), 'WhatsApp é obrigatório');
      expect(CheckoutFormValidator.validatePhone('119876543'), 'WhatsApp inválido (use DDD + número)'); // 9 dígitos
      expect(CheckoutFormValidator.validatePhone('119876543210'), 'WhatsApp inválido (use DDD + número)'); // 12 dígitos
      
      // Válidos com e sem máscara
      expect(CheckoutFormValidator.validatePhone('11987654321'), isNull);
      expect(CheckoutFormValidator.validatePhone('(11) 98765-4321'), isNull);
    });

    test('validateMessage: limite de 200 caracteres', () {
      final longMsg = List.filled(201, 'a').join();
      expect(CheckoutFormValidator.validateMessage(longMsg), 'Mensagem muito longa (máximo 200 caracteres)');
      expect(CheckoutFormValidator.validateMessage('Felicidades!'), isNull);
      expect(CheckoutFormValidator.validateMessage(null), isNull);
    });
  });

  group('Task 6.3: Property Test - Phone Validation', () {
    final random = Random();

    test('Property 3: Só aceita exatamente 10 ou 11 dígitos, independente da formatação', () {
      // Roda 100 testes com strings aleatórias
      for (var i = 0; i < 100; i++) {
        // Gera quantidade aleatória de números (entre 5 e 15)
        final length = 5 + random.nextInt(11);
        String testString = List.generate(length, (_) => random.nextInt(10).toString()).join();

        // Adiciona alguns caracteres especiais aleatórios para simular o usuário digitando
        testString = testString.split('').map((c) => random.nextBool() ? c : '$c- ').join();

        final digitsOnly = testString.replaceAll(RegExp(r'\D'), '');
        final result = CheckoutFormValidator.validatePhone(testString);

        if (digitsOnly.length >= 10 && digitsOnly.length <= 11) {
          expect(result, isNull, reason: 'Deveria ter passado: $testString ($digitsOnly)');
        } else {
          expect(result, isNotNull, reason: 'Deveria ter falhado: $testString ($digitsOnly)');
        }
      }
    });
  });
}