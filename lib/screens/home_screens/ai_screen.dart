import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '/services/groq_service.dart';
import '/services/ai_local_storage.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AiLocalStorageService.init();
    await _loadChat();
  }

  Future<void> _loadChat() async {
    final data = await AiLocalStorageService.loadChat();
    setState(() => messages = data);
  }

  Future<void> _saveChat() async {
    await AiLocalStorageService.saveChat(messages);
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= SEND MESSAGE (FIXED) =================
  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
      controller.clear();
    });

    _saveChat();
    scrollToBottom();

    final systemContext = AiLocalStorageService.systemContext;

    final prompt =
        """
$systemContext

User: $text
AI:
""";

    final reply = await GroqService.sendMessage(prompt);

    setState(() {
      messages.add({"role": "ai", "text": reply});
      isLoading = false;
    });

    _saveChat();
    scrollToBottom();
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Copied")));
  }

  Future<void> _clearChat() async {
    await AiLocalStorageService.clearChat();
    setState(() => messages.clear());
  }

  Widget buildMessage(Map<String, String> msg) {
    final isUser = msg["role"] == "user";
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onLongPress: () => _copyText(msg["text"] ?? ""),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: isUser ? colors.primary : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            msg["text"] ?? "",
            style: TextStyle(
              color: isUser ? colors.onPrimary : colors.onSurface,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 12,
              right: 12,
              bottom: 14,
            ),
            color: theme.appBarTheme.backgroundColor,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/chat'),
                  icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
                ),
                const SizedBox(width: 8),

                Icon(Icons.smart_toy, color: colors.primary),
                const SizedBox(width: 8),

                Text("AI Assistant", style: theme.textTheme.titleLarge),

                const Spacer(),

                IconButton(
                  onPressed: _clearChat,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),

          // CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) => buildMessage(messages[index]),
            ),
          ),

          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(color: colors.primary),
            ),

          // INPUT
          Container(
            padding: const EdgeInsets.all(10),
            color: theme.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(color: colors.onSurface),

                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,

                    decoration: InputDecoration(
                      hintText: "Ask AI Assistant...",
                      hintStyle: TextStyle(
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                  ),
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: Icon(Icons.send, color: colors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
