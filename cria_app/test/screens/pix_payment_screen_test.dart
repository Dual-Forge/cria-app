import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cria_app/features/store_scraping/services/payment_service.dart';
import 'package:cria_app/features/store_scraping/ui/pix_payment_screen.dart';

class MockPaymentService extends Mock implements PaymentService {}

void main() {
  late MockPaymentService mockPaymentService;

  setUp(() {
    mockPaymentService = MockPaymentService();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: PixPaymentScreen(
        paymentId: '12345',
        qrCode: 'codigo_pix_valido',
        qrCodeBase64: 'base64_string',
        familyId: 'fam_123',
        paymentService: mockPaymentService,
      ),
    );
  }

  group('Task 8.5: PixPaymentScreen Widget Tests', () {
    testWidgets('Deve exibir o QR Code, botão de copiar e timer inicial', (tester) async {
      // Mock para o polling não falhar logo de cara
      when(() => mockPaymentService.checkPaymentStatus('12345'))
          .thenAnswer((_) async => {'status': 'pending'});

      await tester.pumpWidget(createTestWidget());

      // Verifica QR Code
      expect(find.byType(QrImageView), findsOneWidget);
      
      // Verifica o botão de copiar
      expect(find.text('Copiar Código PIX'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);

      // Verifica o timer inicial (10:00)
      expect(find.text('Expira em: 10:00'), findsOneWidget);
    });

    testWidgets('Timer deve decrementar a cada segundo', (tester) async {
      when(() => mockPaymentService.checkPaymentStatus('12345'))
          .thenAnswer((_) async => {'status': 'pending'});

      await tester.pumpWidget(createTestWidget());
      
      // Avança 2 segundos virtuais
      await tester.pump(const Duration(seconds: 2));

      // Timer deve mostrar 09:58
      expect(find.text('Expira em: 09:58'), findsOneWidget);
    });

    testWidgets('Deve redirecionar para tela de sucesso quando pagamento for aprovado', (tester) async {
      // Configura o mock para retornar "approved" na primeira checagem
      when(() => mockPaymentService.checkPaymentStatus('12345'))
          .thenAnswer((_) async => {'status': 'approved'});

      await tester.pumpWidget(createTestWidget());
      
      // Avança 3 segundos (tempo do polling)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Deve achar a tela de sucesso
      expect(find.text('Pagamento Aprovado! 🎉'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing); // A tela de PIX deve ter saído
    });
  });
}