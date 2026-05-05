/// GeminiService
///
/// Responsabilidade única: lógica de IA (Gemini API).
/// Persistência de mensagens → ChatRepository.
/// Configuração de chaves → EnvConfig.
library;

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:cria_app/core/config/env_config.dart';

class GeminiService {
  /// Chave resolvida via EnvConfig (dart-define → .env → vazio)
  static String get _apiKey => EnvConfig.geminiApiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  GenerativeModel _createModel({String? customSystemInstruction}) {
    const defaultInstruction = '''
Você é a 'Cria AI', uma assistente virtual especializada em maternidade, paternidade, saúde infantil e puerpério.
Seu objetivo é apoiar mães e pais de forma empática, clara e acolhedora.
IMPORTANTE: Sempre que houver suspeita de problemas de saúde, febre alta, dores fortes ou sangramento, avise que suas dicas não substituem a consulta de um médico.
Use uma linguagem amorosa, fuja do tom robótico.
As mensagens devem ser EXTREMAMENTE CURTAS E DIRETAS (no máximo 2 ou 3 frases curtas por resposta).
''';

    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        customSystemInstruction ?? defaultInstruction,
      ),
    );
  }

  /// Retorna insights gestacionais como mapa JSON.
  ///
  /// Chaves retornadas: body, nutrition, baby, mind, movement, connection
  Future<Map<String, String>?> getPregnancyInsights(
    int week,
    Map<String, dynamic> userData,
  ) async {
    if (!isConfigured) return null;

    final roleDesc = userData['role'] == 'pai' ? 'o pai' : 'a mãe';

    try {
      final prompt = '''
A usuária está na semana gestacional: $week.
Lembre-se: O USUÁRIO LOGADO VENDO ESTA MENSAGEM AGORA É: $roleDesc.
Aqui estão alguns dados extra da família: ${jsonEncode(userData)}.
Por favor, retorne UM ÚNICO JSON válido (sem blocos de código markdown como ```json) contendo exatamente estas chaves:
{
  "body": "Dica extremamente curta (1 frase) sobre o corpo nesta semana.",
  "nutrition": "Dica curtíssima (1 frase) de nutrição.",
  "baby": "Fato rápido (1 frase) sobre o bebê na semana $week.",
  "mind": "Dica rápida (1 frase) sobre saúde mental e emoções.",
  "movement": "Dica curta (1 frase) sobre exercícios ou movimento.",
  "connection": "Dica rápida (1 frase) sobre conexão entre o casal ou família."
}
''';

      final model = _createModel();
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        final text = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> data = jsonDecode(text);
        return {
          'body': data['body']?.toString() ?? '',
          'nutrition': data['nutrition']?.toString() ?? '',
          'baby': data['baby']?.toString() ?? '',
          'mind': data['mind']?.toString() ?? '',
          'movement': data['movement']?.toString() ?? '',
          'connection': data['connection']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('[GeminiService] Erro ao gerar insights: $e');
    }
    return null;
  }

  /// Inicia uma sessão de chat com histórico e contexto dinâmico de usuário.
  ChatSession startChat(
    List<Content> history, {
    Map<String, dynamic>? userData,
  }) {
    String? dynamicInstruction;

    if (userData != null) {
      final userRole = userData['role'] ?? 'mae';
      final userName = userData['userName'] ?? '';
      final babyName = userData['babyName'] ?? 'Bebê';

      dynamicInstruction = """
Você é a Nanda, uma especialista virtual empática e acolhedora do aplicativo de gravidez 'Cria'.
Seu tom deve ser doce, paciente e acolhedor, utilizando emojis suaves como ✨ e 🤍.
Você nunca deve dar diagnósticos médicos definitivos. Sempre valide a ansiedade, medos e dúvidas dos pais antes de responder.
Ofereça conselhos práticos de bem-estar, dicas de gravidez e apoio emocional.
Se a pergunta for sobre saúde clínica grave, oriente os pais a procurarem o obstetra ou pediatra.

Parâmetros dinâmicos: {{user_name}} ($userName), {{user_role}} ($userRole) e {{baby_name}} ($babyName).
O USUÁRIO QUE ESTÁ FALANDO COM VOCÊ AGORA É O/A ${userRole == 'mae' ? 'MÃE' : 'PAI'} E SE CHAMA $userName.
O BEBÊ DESSA FAMÍLIA SE CHAMA $babyName.
NUNCA CONFUNDA: Quem está interagindo com você é o adulto ($userName). O bebê ($babyName) é o filho(a) sobre o qual vocês estão conversando.
Ao se referir ao interlocutor, use obrigatoriamente $userName ou tratamentos adequados (ex: papai/mamãe).
Ao se referir ao bebê da gestação, use obrigatoriamente $babyName.
As mensagens devem ser EXTREMAMENTE CURTAS E DIRETAS (no máximo 2 ou 3 frases curtas por resposta).
""";
    }

    final model = _createModel(customSystemInstruction: dynamicInstruction);
    return model.startChat(history: history);
  }
}
