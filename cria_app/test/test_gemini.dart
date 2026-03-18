import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  // API key deve ser injetada via variável de ambiente GEMINI_API_KEY
  final apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

  try {
    final response = await model.generateContent([Content.text('Hello')]);
    print(response.text);
  } catch (e) {
    print('Exception occurred:');
    print(e.toString());
  }
}
