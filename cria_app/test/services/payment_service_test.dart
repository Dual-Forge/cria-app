import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cria_app/services/payment_service.dart';

// 1. Criar os Mocks (Simuladores) do Supabase
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late PaymentService paymentService;
  late MockSupabaseClient mockSupabaseClient;
  late MockFunctionsClient mockFunctionsClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockFunctionsClient = MockFunctionsClient();
    
    // Dizemos ao Supabase mockado para retornar o nosso FunctionsClient mockado
    when(() => mockSupabaseClient.functions).thenReturn(mockFunctionsClient);
    
    paymentService = PaymentService(mockSupabaseClient);
  });

  group('Task 7.3: PaymentService Unit Tests', () {
    final dummyItems = [{'id': 'item_1', 'price': 100, 'qty': 1}];

    test('createCheckout: retorna os dados do PIX com sucesso na primeira tentativa', () async {
      // Prepara o Mock para devolver um sucesso (HTTP 200)
      when(() => mockFunctionsClient.invoke(
            'create-checkout-api',
            body: any(named: 'body'),
          )).thenAnswer((_) async => FunctionResponse(
            data: {'payment_id': 12345, 'qr_code': 'pix_code_abc'}, 
            status: 200
          ));

      final result = await paymentService.createCheckout(
        items: dummyItems,
        familyId: 'fam_123',
        giverName: 'Jean',
        giverPhone: '11987654321',
      );

      expect(result['payment_id'], 12345);
      expect(result['qr_code'], 'pix_code_abc');
      
      // Verifica se a função foi chamada exatamente 1 vez
      verify(() => mockFunctionsClient.invoke('create-checkout-api', body: any(named: 'body'))).called(1);
    });

    test('createCheckout: faz retry em caso de erro e lança exceção após 3 tentativas', () async {
      // Prepara o Mock para simular um erro de rede (estoura uma exceção)
      when(() => mockFunctionsClient.invoke(
            'create-checkout-api',
            body: any(named: 'body'),
          )).thenThrow(Exception('Sem internet'));

      // Como ele vai tentar 3 vezes (com intervalos de 2s e 4s), o teste demoraria 6s.
      // O expect valida se ele realmente lança o erro final de tentativas excedidas.
      expect(
        () => paymentService.createCheckout(
          items: dummyItems,
          familyId: 'fam_123',
          giverName: 'Jean',
          giverPhone: '11987654321',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 
          'message', 
          contains('Falha de conexão após 3 tentativas')
        )),
      );
    }, timeout: const Timeout(Duration(seconds: 10))); // Dá tempo extra para os delays do retry

    test('checkPaymentStatus: devolve o estado correto do pagamento (approved/pending)', () async {
      when(() => mockFunctionsClient.invoke(
            'check-payment-status',
            method: HttpMethod.get,
            queryParameters: {'payment_id': '12345'},
          )).thenAnswer((_) async => FunctionResponse(
            data: {'status': 'approved', 'status_detail': 'accredited'}, 
            status: 200
          ));

      final result = await paymentService.checkPaymentStatus('12345');

      expect(result['status'], 'approved');
      expect(result['status_detail'], 'accredited');
    });
  });
}