/// AIService
///
/// Responsabilidade única: lógica de IA via Edge Function `ai-proxy`
/// (Supabase). A GROQ_API_KEY NUNCA é embarcada no app — ela vive apenas
/// como variável de ambiente da função (ver supabase/functions/ai-proxy).
/// Persistência de mensagens → ChatRepository.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIService {
  /// Client Supabase injetado (FASE 5 / DI). Usa `functions.invoke` p/ o proxy.
  final SupabaseClient client;

  AIService(this.client);

  /// Configurado quando o Supabase está inicializado — o proxy exige JWT
  /// de usuário autenticado (verify_jwt = true) e a chave fica no servidor.
  bool get isConfigured => true;

  // ── Helpers internos ──────────────────────────────────────────────────────

  /// Executa uma chamada ao proxy `ai-proxy` e devolve o texto da resposta.
  Future<String?> _chat({
    required List<Map<String, String>> messages,
    bool jsonMode = false,
    double temperature = 0.7,
  }) async {
    try {
      final response = await client.functions
          .invoke(
            'ai-proxy',
            body: {
              'messages': messages,
              'temperature': temperature,
              if (jsonMode) 'json_mode': true,
            },
          )
          .timeout(const Duration(seconds: 30));

      final data = response.data as Map<String, dynamic>?;
      final content = data?['content'] as String?;
      if (content != null && content.isNotEmpty) {
        return content;
      }
      debugPrint(
        '[AIService] Proxy retornou resposta vazia ou sem "content".',
      );
    } catch (e) {
      debugPrint('[AIService] Erro na chamada ao proxy: $e');
    }
    return null;
  }

  // ── Chat da Nanda ─────────────────────────────────────────────────────────

  /// Envia o histórico completo ao proxy e devolve a resposta da Nanda.
  ///
  /// [history] é uma lista de `{"role": "user"|"assistant", "content": "..."}`.
  /// O System Prompt da Nanda é SEMPRE injetado como primeiro item.
  Future<String> sendChatMessage({
    required List<Map<String, String>> history,
    String userName = '',
    String userRole = 'mae',
    String babyName = 'Bebê',
  }) async {
    final systemPrompt =
        '''
Você é a Nanda, uma especialista virtual empática e acolhedora do aplicativo de gravidez "Cria".
Seu tom deve ser doce, paciente e acolhedor, utilizando emojis suaves como ✨ e 🤍.
Você nunca deve dar diagnósticos médicos definitivos. Sempre valide a ansiedade, medos e dúvidas dos pais antes de responder.
Ofereça conselhos práticos de bem-estar, dicas de gravidez e apoio emocional.
Se a pergunta for sobre saúde clínica grave, oriente os pais a procurarem o obstetra ou pediatra.

O USUÁRIO QUE ESTÁ FALANDO COM VOCÊ AGORA É O/A ${userRole == 'mae' ? 'MÃE' : 'PAI'} E SE CHAMA $userName.
O BEBÊ DESSA FAMÍLIA SE CHAMA $babyName.
NUNCA CONFUNDA: Quem interage com você é o adulto ($userName). O bebê ($babyName) é o filho(a) sobre o qual conversam.
Ao se referir ao interlocutor, use $userName ou tratamentos adequados (ex: papai/mamãe).
Ao se referir ao bebê, use obrigatoriamente $babyName.
As mensagens devem ser CURTAS E DIRETAS (de 2 a 3 frases curtas por resposta).
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
    ];

    final reply = await _chat(messages: messages);
    return reply ?? 'Desculpe, não consegui entender. Pode repetir? 🤍';
  }

  // ── Insights Gestacionais ─────────────────────────────────────────────────

  /// Retorna insights gestacionais como mapa JSON.
  ///
  /// Chaves retornadas: body, nutrition, baby, mind, movement, connection
  Future<Map<String, String>?> getPregnancyInsights(
    int week,
    Map<String, dynamic> userData,
  ) async {
    if (!isConfigured) return null;

    // Tratamento rigoroso das strings para evitar espaços em branco ou nulos
    final rawMotherName = userData['mother_name']?.toString().trim() ?? '';
    final rawFatherName = userData['father_name']?.toString().trim() ?? '';

    final motherTitle = rawMotherName.isNotEmpty
        ? 'mamãe $rawMotherName'
        : 'a mamãe';
    final fatherTitle = rawFatherName.isNotEmpty
        ? 'papai $rawFatherName'
        : 'o papai';
    final babyName = userData['baby_name']?.toString().trim() ?? 'o bebê';

    // 1. System Prompt: Autoridade Médica + Formato Restrito
    final systemPrompt = '''
Você é o motor de inteligência médica e afetiva do aplicativo Cria.
Sua missão é traduzir dados biológicos reais da obstetrícia (baseados na OMS e literatura médica global) em mensagens curtas, acolhedoras e humanizadas.

DIRETRIZES TÉCNICAS E CLÍNICAS:
- ZERO ALUCINAÇÃO: As medidas e pesos fetais DEVEM ser exatas para a semana gestacional informada. Nunca extrapole.
- PROIBIDO jargão clínico frio: Nunca use as palavras "feto", "a gestante", "a mulher" ou "o indivíduo".

DIRETRIZES DE SAÍDA:
- Responda ÚNICA E EXCLUSIVAMENTE com um objeto JSON válido.
- Não adicione introduções, explicações ou formatação markdown fora do JSON.
''';

    // 2. User Prompt: Injeção de variáveis e Template Constraint
    final prompt =
        '''
Semana Gestacional Atual: $week
Mãe: $motherTitle
Pai: $fatherTitle
Bebê: $babyName

Com base na literatura médica real para exatamente $week semanas de gestação, preencha o JSON abaixo.
Substitua as instruções entre colchetes < > pelo conteúdo gerado, integrando naturalmente os nomes fornecidos:

{
  "body": "<2 frases acolhedoras explicando o que está acontecendo no corpo da $motherTitle nesta semana exata.>",
  "nutrition": "<2 frases com uma recomendação nutricional específica e prática voltada para a saúde da $motherTitle.>",
  "baby": "<2 frases sobre a formação do $babyName nesta semana. É OBRIGATÓRIO informar o peso e o comprimento médios reais esperados para $week semanas.>",
  "mind": "<2 frases empáticas validando os sentimentos comuns desta fase e trazendo conforto para a $motherTitle e o $fatherTitle.>",
  "movement": "<2 frases sugerindo um tipo de movimento ou alívio físico adequado e seguro para a $motherTitle.>",
  "connection": "<2 frases sugerindo uma pequena ação para fortalecer o vínculo entre a $motherTitle, o $fatherTitle e o $babyName.>"
}
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt},
    ];

    try {
      // Temperatura em 0.2: Ideal para manter os fatos médicos cravados, mas com uma leve fluidez no texto
      final text = await _chat(
        messages: messages,
        jsonMode: true,
        temperature: 0.2,
      );

      if (text == null) return null;

      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> data = jsonDecode(cleaned);
      return {
        'body': data['body']?.toString() ?? '',
        'nutrition': data['nutrition']?.toString() ?? '',
        'baby': data['baby']?.toString() ?? '',
        'mind': data['mind']?.toString() ?? '',
        'movement': data['movement']?.toString() ?? '',
        'connection': data['connection']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('[AIService] Erro ao gerar insights: $e');
      return null;
    }
  }
}