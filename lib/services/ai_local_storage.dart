import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AiLocalStorageService {
  static const _chatKey = "ai_chat_messages";

  static const String systemContext = """
You are "AI Assistant" inside the SafeConnect app.

You are a general-purpose AI assistant like ChatGPT.

CAPABILITIES:
- You can answer ANY general knowledge questions (science, history, coding, geography, etc.)
- You can have normal conversations
- You can help with explanations, learning, and problem solving

SAFECONNECT KNOWLEDGE (ONLY THIS IS GUARANTEED TRUE):
SafeConnect is a social chat application with:
- User profiles with profile pictures
- Real-time messaging between users
- Friend request system (send / accept / reject)
- User search system
- Online/offline status
- Push notifications

IMPORTANT RULES:
- If asked about SafeConnect, ONLY use the features listed above
- DO NOT invent or assume extra SafeConnect features
- For all other topics, behave like a normal AI assistant
- Never say "I don't have that feature" for general knowledge questions
- If something is uncertain, respond normally with best known information
- Keep responses clear, helpful, and not too long
""";

  // INIT (safe)
  static Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  // LOAD CHAT
  static Future<List<Map<String, String>>> loadChat() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_chatKey);

    if (data == null) return [];

    return List<Map<String, String>>.from(
      jsonDecode(data).map((e) => Map<String, String>.from(e)),
    );
  }

  // SAVE CHAT
  static Future<void> saveChat(List<Map<String, String>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatKey, jsonEncode(messages));
  }

  // CLEAR CHAT
  static Future<void> clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatKey);
  }
}
