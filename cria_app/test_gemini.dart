import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyAZHuiInkMzYfMTXKhrDe0J0GY0WVe2erE';
  final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

  try {
    final response = await model.generateContent([Content.text('Hello')]);
    print(response.text);
  } catch (e) {
    print('Exception occurred:');
    print(e.toString());
  }
}
