import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static Future<String> sendMessage(String message) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return "API key missing";
    }

    final url = "https://api.groq.com/openai/v1/chat/completions";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "user", "content": message},
        ],
        "temperature": 0.7,
      }),
    );

    final data = jsonDecode(response.body);

    if (data["error"] != null) {
      return "Error: ${data["error"]["message"]}";
    }

    return data["choices"][0]["message"]["content"];
  }
}
