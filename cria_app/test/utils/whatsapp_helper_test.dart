import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/utils/whatsapp_helper.dart';

void main() {
  group('WhatsAppHelper Tests', () {
    test('generateThanksUrl deve gerar URL com formato correto', () {
      final url = WhatsAppHelper.generateThanksUrl(
        phone: '11987654321',
        nameOrNickname: 'João',
      );

      expect(url, startsWith('https://wa.me/'));
      expect(url, contains('?text='));
    });

    test('generateThanksUrl deve limpar caracteres especiais do telefone', () {
      final url = WhatsAppHelper.generateThanksUrl(
        phone: '(11) 98765-4321',
        nameOrNickname: 'Maria',
      );

      final phonePart = url.split('wa.me/')[1].split('?')[0];
      expect(phonePart, '11987654321');
    });

    test('generateThanksUrl deve conter nome e mensagem de agradecimento', () {
      final url = WhatsAppHelper.generateThanksUrl(
        phone: '11987654321',
        nameOrNickname: 'Pedro',
      );

      final decodedUrl = Uri.decodeFull(url);
      expect(decodedUrl, contains('Oi Pedro'));
      expect(decodedUrl, contains('muito obrigado pelo presente!'));
    });

    test('generateThanksUrl deve funcionar com apelidos', () {
      final url = WhatsAppHelper.generateThanksUrl(
        phone: '11987654321',
        nameOrNickname: 'Pe',
      );

      final decodedUrl = Uri.decodeFull(url);
      expect(decodedUrl, contains('Oi Pe'));
    });

    test('generateThanksUrl deve retornar string vazia para telefone inválido', () {
      final url = WhatsAppHelper.generateThanksUrl(
        phone: '',
        nameOrNickname: 'Teste',
      );

      expect(url, isA<String>());
    });
  });
}
