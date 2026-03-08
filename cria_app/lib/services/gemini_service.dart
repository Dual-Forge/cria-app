import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // 1. Tenta pegar a chave injetada via compilação na Vercel (--dart-define)
  static const String _envKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // 2. Fallback para o .env no emulador local
  static String get _apiKey {
    if (_envKey.isNotEmpty) return _envKey;
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  GenerativeModel _createModel({String? customSystemInstruction}) {
    final defaultInstruction = '''
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

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Retorna um Insight Dinâmico para a página de Gravidez (JSON esperado)
  Future<Map<String, String>?> getPregnancyInsights(
    int week,
    Map<String, dynamic> userData,
  ) async {
    if (!isConfigured) return null;

    final roleDesc = userData['role'] == 'pai' ? 'o pai' : 'a mãe';

    try {
      final prompt =
          '''
A usuária está na semana gestacional: $week.
Lembre-se: O USUÁRIO LOGADO VENDO ESTA MENSAGEM AGORA É: $roleDesc.
Aqui estão alguns dados extra da família: ${jsonEncode(userData)}.
Por favor, retorne UM ÚNICO JSON válido (sem blocos de código markdown como ```json) contendo exatamente estas chaves:
{
  "body": "Dica extremamente curta (1 frase) sobre o corpo nesta semana.",
  "nutrition": "Dica curtíssima (1 frase) de nutrição.",
  "baby": "Fato rápido (1 frase) sobre o bebê na semana $week.",
  "mind": "Dica rápida (1 frase) sobre saúde mental e emoções.",
  "movement": "Dica curta (1 frase) sobre exercícios ou movimento."
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
        };
      }
    } catch (e) {
      debugPrint('Error generating insights: $e');
    }
    return null;
  }

  /// Inicia uma sessão de chat enviando o histórico
  ChatSession startChat(
    List<Content> history, {
    Map<String, dynamic>? userData,
  }) {
    String? dynamicInstruction;

    if (userData != null) {
      final userRole = userData['role'] ?? 'mae';
      final userName = userData['userName'] ?? '';
      final babyName = userData['babyName'] ?? 'Bebê';

      dynamicInstruction =
          """
Você é o Cria Especialista.
Você receberá os seguintes parâmetros dinâmicos: {{user_name}} ($userName), {{user_role}} ($userRole) e {{baby_name}} ($babyName).
O USUÁRIO QUE ESTÁ FALANDO COM VOCÊ AGORA É O/A ${userRole == 'mae' ? 'MÃE' : 'PAI'} E SE CHAMA $userName. 
O BEBÊ DESSA FAMÍLIA SE CHAMA $babyName.
NUNCA CONFUNDA: Quem está interagindo com você é o adulto ($userName). O bebê ($babyName) é o filho(a) sobre o qual vocês estão conversando. NUNCA trate o interlocutor como se fosse o bebê.
Ao se referir ao interlocutor, use obrigatoriamente {{user_name}} ($userName) ou tratamentos adequados (ex: papai/mamãe).
Ao se referir ao bebê da gestação, use obrigatoriamente {{baby_name}} ($babyName).
Sempre diferencie $userName de $babyName nas suas orientações.
IMPORTANTE: Sempre que houver suspeita de problemas de saúde, febre alta, dores fortes ou sangramento, avise que suas dicas não substituem a consulta de um médico.
As mensagens devem ser EXTREMAMENTE CURTAS E DIRETAS (no máximo 2 ou 3 frases curtas por resposta).
""";
    }

    final model = _createModel(customSystemInstruction: dynamicInstruction);
    return model.startChat(history: history);
  }

  /// Salva mensagem no Supabase
  Future<void> saveMessageToSupabase(String content, String role) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Tenta buscar o family_id
      String? familyId;
      try {
        final profile = await client
            .from('profiles')
            .select('family_id')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null && profile['family_id'] != null) {
          familyId = profile['family_id'];
        }
      } catch (innerE) {
        debugPrint('Erro ao buscar family_id: \$innerE');
      }

      await client.from('chat_messages').insert({
        'user_id': user.id,
        'family_id': familyId,
        'role': role,
        'content': content,
      });
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }
}
