import 'dart:async';

class PregnancyTip {
  final String category;
  final String content;
  final String iconEmoji;

  PregnancyTip({
    required this.category,
    required this.content,
    required this.iconEmoji,
  });
}

class PregnancyAIService {
  // Singleton pattern for easy access
  static final PregnancyAIService _instance = PregnancyAIService._internal();
  factory PregnancyAIService() => _instance;
  PregnancyAIService._internal();

  /// Simulates an AI fetch for pregnancy tips based on the current week.
  /// In the future, this can be replaced with an actual API call to an LLM.
  Future<List<PregnancyTip>> fetchTipsForWeek(int week) async {
    // Simulate network delay for "AI" feel
    await Future.delayed(const Duration(milliseconds: 600));

    // Fallback logic (current hardcoded rules, but structured closer to AI response)
    if (week < 12) {
      return [
        PregnancyTip(
          category: "Corpo",
          content: "Seu corpo está se adaptando! Sono e náuseas são normais.",
          iconEmoji: "🧘‍♀️",
        ),
        PregnancyTip(
          category: "Nutrição",
          content: "Ácido Fólico é essencial agora. Beba muita água!",
          iconEmoji: "🥦",
        ),
        PregnancyTip(
          category: "Movimento",
          content: "Caminhadas leves ajudam na circulação.",
          iconEmoji: "🚶‍♀️",
        ),
        PregnancyTip(
          category: "Mente",
          content: "Descanse. Você está 'construindo' um ser humano!",
          iconEmoji: "🧠",
        ),
        PregnancyTip(
          category: "Bebê",
          content: "O coração já bate forte e rápido!",
          iconEmoji: "❤️",
        ),
        PregnancyTip(
          category: "Conexão",
          content: "Vocês estão criando um laço invisível e eterno.",
          iconEmoji: "🤍",
        ),
      ];
    } else if (week < 20) {
      return [
        PregnancyTip(
          category: "Corpo",
          content: "A barriguinha começa a aparecer! Hidrate bem a pele.",
          iconEmoji: "🧴",
        ),
        PregnancyTip(
          category: "Nutrição",
          content: "Invista em alimentos ricos em Cálcio.",
          iconEmoji: "🥛",
        ),
        PregnancyTip(
          category: "Movimento",
          content: "Yoga ou Pilates são ótimos para flexibilidade.",
          iconEmoji: "🧘",
        ),
        PregnancyTip(
          category: "Mente",
          content: "Converse com o bebê, ele já sente vibrações.",
          iconEmoji: "🎵",
        ),
        PregnancyTip(
          category: "Bebê",
          content: "As digitais dos dedinhos estão se formando.",
          iconEmoji: "👆",
        ),
        PregnancyTip(
          category: "Conexão",
          content: "Reservem um momento a dois para celebrar a vida.",
          iconEmoji: "🤍",
        ),
      ];
    } else if (week < 28) {
      return [
        PregnancyTip(
          category: "Corpo",
          content: "Seu centro de gravidade mudou. Cuidado com a postura.",
          iconEmoji: "⚖️",
        ),
        PregnancyTip(
          category: "Nutrição",
          content: "Ferro é vital para evitar anemia.",
          iconEmoji: "🥩",
        ),
        PregnancyTip(
          category: "Movimento",
          content: "Hidroginástica alivia o peso da barriga.",
          iconEmoji: "🏊‍♀️",
        ),
        PregnancyTip(
          category: "Mente",
          content: "Comece a planejar o quartinho sem pressa.",
          iconEmoji: "🎨",
        ),
        PregnancyTip(
          category: "Bebê",
          content: "Ele já consegue ouvir sua voz!",
          iconEmoji: "👂",
        ),
        PregnancyTip(
          category: "Conexão",
          content: "Leiam uma história juntos para o bebê.",
          iconEmoji: "🤍",
        ),
      ];
    } else {
      return [
        PregnancyTip(
          category: "Corpo",
          content: "Reta final! Inchaço é comum, eleve as pernas.",
          iconEmoji: "🦶",
        ),
        PregnancyTip(
          category: "Nutrição",
          content: "Fibras ajudam no funcionamento do intestino.",
          iconEmoji: "🍎",
        ),
        PregnancyTip(
          category: "Movimento",
          content: "Alongamentos para aliviar dores nas costas.",
          iconEmoji: "🙆‍♀️",
        ),
        PregnancyTip(
          category: "Mente",
          content: "A mala da maternidade está pronta?",
          iconEmoji: "🧳",
        ),
        PregnancyTip(
          category: "Bebê",
          content: "Ganhando peso e se preparando para nascer.",
          iconEmoji: "👶",
        ),
        PregnancyTip(
          category: "Conexão",
          content: "Conversem sobre os medos e expectativas, vocês são uma equipe.",
          iconEmoji: "🤍",
        ),
      ];
    }
  }

  /// Returns a 'hero' tip for the week
  Future<String> getWeeklyFocus(int week) async {
    if (week < 12) return "Adaptação e Formação";
    if (week < 20) return "Crescimento e Movimento";
    if (week < 28) return "Conexão e Desenvolvimento";
    return "Preparação para o Encontro";
  }
}
