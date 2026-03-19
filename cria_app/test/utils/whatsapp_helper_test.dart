import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart';
import 'package:cria_app/utils/whatsapp_helper.dart';

void main() {
  group('Task 11: WhatsApp Link Properties', () {
    
    // Property 12: WhatsApp URL Format
    Glados2(any.letterOrDigitString, any.letterOrDigitString).test(
      'A URL do WhatsApp deve sempre ter o formato correto e telefone limpo',
      (phone, name) {
        final url = WhatsAppHelper.generateThanksUrl(
          phone: phone, 
          nameOrNickname: name
        );

        if (url.isNotEmpty) {
          expect(url, startsWith('https://wa.me/'));
          expect(url, contains('?text='));
          // Garante que não há parênteses ou espaços no link do número
          final phonePart = url.split('wa.me/')[1].split('?')[0];
          expect(RegExp(r'^[0-9]*$').hasMatch(phonePart), isTrue);
        }
      },
    );

    // Property 13: WhatsApp Message Format
    Glados(any.letterOrDigitString).test(
      'A mensagem deve sempre conter o nome/apelido e o agradecimento padrão',
      (name) {
        final url = WhatsAppHelper.generateThanksUrl(
          phone: '11987654321', 
          nameOrNickname: name
        );

        // Decodifica a URL para verificar o texto puramente
        final decodedUrl = Uri.decodeFull(url);
        expect(decodedUrl, contains('Oi $name'));
        expect(decodedUrl, contains('muito obrigado pelo presente! 💛'));
      },
    );
  });
}