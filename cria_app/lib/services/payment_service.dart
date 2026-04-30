import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _supabase;

  PaymentService(this._supabase);

  /// Chama a Edge Function para criar o PIX no Mercado Pago
  Future<Map<String, dynamic>> createCheckout({
    required List<Map<String, dynamic>> items,
    required String familyId,
    required String giverName,
    required String giverPhone,
    required String giverNickname,
    required String giverEmail,
    String? messageToParents,
  }) async {
    int attempts = 0;
    const maxRetries = 3;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Timeout de 30 segundos conforme requisito
        final response = await _supabase.functions
            .invoke(
              'create-checkout-api',
              body: {
                'items': items,
                'family_id': familyId,
                'giver_name': giverName,
                'giver_phone': giverPhone,
                'giver_nickname': giverNickname,
                'giver_email': giverEmail,
                'message_to_parents': messageToParents,
              },
            )
            .timeout(const Duration(seconds: 30));

        if (response.status == 200) {
          return response
              .data; // Retorna os dados do PIX (qr_code, payment_id, etc)
        } else {
          // Parseia erros amigáveis vindos da Edge Function (ex: 503 do MP)
          final errorMsg =
              response.data['error'] ?? 'Erro desconhecido ao gerar pagamento';
          throw Exception(errorMsg);
        }
      } catch (e) {
        // Se for a última tentativa, joga o erro para a tela
        if (attempts >= maxRetries) {
          throw Exception(
            'Falha de conexão após $maxRetries tentativas. Verifique sua internet.',
          );
        }
        // Espera um pouco antes de tentar de novo (Backoff: 2s, 4s...)
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
    throw Exception('Erro inesperado na geração do pagamento');
  }

  /// Chama a Edge Function para verificar se o PIX já foi pago
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      final response = await _supabase.functions
          .invoke(
            'check-payment-status',
            method: HttpMethod.get,
            queryParameters: {'payment_id': paymentId},
          )
          .timeout(const Duration(seconds: 30));

      if (response.status == 200) {
        return response.data; // Retorna { status: 'approved' | 'pending' }
      } else {
        throw Exception(response.data['error'] ?? 'Erro ao consultar status');
      }
    } catch (e) {
      throw Exception(
        'Erro de conexão ao verificar pagamento. Tente novamente.',
      );
    }
  }
}
