import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicalApiService {
  static const String _apiKey =
      'YOUR_OPENAI_API_KEY'; // <-- Replace with your OpenAI API key
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  static Future<String> askMedicalQuestion(String question) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a helpful medical assistant. Answer medical questions accurately and safely. If asked for diagnosis or treatment, provide general advice and recommend seeing a healthcare professional for serious issues.",
          },
          {"role": "user", "content": question},
        ],
        "max_tokens": 256,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      return "Sorry, I couldn't fetch an answer right now.";
    }
  }
}
