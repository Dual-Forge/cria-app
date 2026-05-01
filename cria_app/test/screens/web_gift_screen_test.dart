import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cria_app/services/payment_service.dart';
import 'package:cria_app/screens/web_gift_screen.dart';

class MockPaymentService extends Mock implements PaymentService {}

void main() {
  late MockPaymentService mockPaymentService;

  setUp(() {
    mockPaymentService = MockPaymentService();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: WebGiftScreen(
        paymentService: mockPaymentService,
        familyId: 'fam_123',
        selectedItems: const [{'id': 'item_1', 'price': 50}],
      ),
    );
  }

  group('WebGiftScreen Widget Tests', () {
    testWidgets('Deve exibir erros de validação ao enviar formulário vazio', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Clica no botão "Gerar PIX" sem preencher nada
      await tester.tap(find.text('Gerar PIX'));
      await tester.pumpAndSettle();

      // Verifica se as mensagens de erro dos validadores apareceram na tela
      expect(find.text('Campo obrigatório'), findsAtLeast(1));
    });

    testWidgets('Deve chamar createCheckout ao preencher dados válidos', (tester) async {
      // Mock da resposta de sucesso do backend
      when(() => mockPaymentService.createCheckout(
            items: any(named: 'items'),
            familyId: any(named: 'familyId'),
            giverName: any(named: 'giverName'),
            giverNickname: any(named: 'giverNickname'),
            giverPhone: any(named: 'giverPhone'),
            giverEmail: any(named: 'giverEmail'),
            messageToParents: any(named: 'messageToParents'),
          )).thenAnswer((_) async => {
                'payment_id': '12345',
                'qr_code': 'codigo_pix_valido',
              });

      await tester.pumpWidget(createTestWidget());

      // Preenche o formulário
      await tester.enterText(find.widgetWithText(TextFormField, 'Seu Nome Completo *'), 'João Silva');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-mail *'), 'joao@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'WhatsApp (com DDD) *'), '11987654321');

      // Clica no botão
      await tester.tap(find.text('Gerar PIX'));
      await tester.pump(); // Inicia o loading

      // Verifica se a função do serviço foi chamada exatamente 1 vez
      verify(() => mockPaymentService.createCheckout(
        items: any(named: 'items'),
        familyId: 'fam_123',
        giverName: 'João Silva',
        giverNickname: any(named: 'giverNickname'),
        giverPhone: '11987654321',
        giverEmail: 'joao@test.com',
        messageToParents: any(named: 'messageToParents'),
      )).called(1);
    });

    testWidgets('Deve exibir SnackBar em caso de erro da API', (tester) async {
      // Mock forçando um erro
      when(() => mockPaymentService.createCheckout(
            items: any(named: 'items'),
            familyId: any(named: 'familyId'),
            giverName: any(named: 'giverName'),
            giverNickname: any(named: 'giverNickname'),
            giverPhone: any(named: 'giverPhone'),
            giverEmail: any(named: 'giverEmail'),
            messageToParents: any(named: 'messageToParents'),
          )).thenThrow(Exception('Serviço indisponível'));

      await tester.pumpWidget(createTestWidget());

      // Preenche o formulário
      await tester.enterText(find.widgetWithText(TextFormField, 'Seu Nome Completo *'), 'João Silva');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-mail *'), 'joao@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'WhatsApp (com DDD) *'), '11987654321');

      // Clica no botão e espera a SnackBar
      await tester.tap(find.text('Gerar PIX'));
      await tester.pumpAndSettle();

      // Verifica se a mensagem de erro apareceu na tela
      expect(find.text('Serviço indisponível'), findsOneWidget);
    });
  });
}
