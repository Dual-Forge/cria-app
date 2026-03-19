import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cria_app/screens/confirmation_screen.dart';

void main() {
  group('Task 9.2: ConfirmationScreen Widget Tests', () {
    
    testWidgets('Deve exibir mensagem de sucesso com o nome do bebê', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConfirmationScreen(babyName: 'Enzo'),
        ),
      );

      // Verifica o ícone
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verifica o título
      expect(find.text('Pagamento Aprovado! 🎉'), findsOneWidget);

      // Verifica se o nome do bebê "Enzo" foi inserido corretamente no texto
      expect(find.textContaining('Enzo vai adorar!'), findsOneWidget);
    });

    testWidgets('Deve acionar o callback ao clicar em Voltar para a lista', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ConfirmationScreen(
            babyName: 'Valentina',
            onReturnHome: () {
              buttonPressed = true;
            },
          ),
        ),
      );

      // Encontra o botão
      final returnButton = find.text('Voltar para lista de presentes');
      expect(returnButton, findsOneWidget);

      // Simula o clique
      await tester.tap(returnButton);
      await tester.pumpAndSettle();

      // Confirma que a ação de retorno foi disparada
      expect(buttonPressed, isTrue);
    });
    
  });
}