import 'package:flutter/material.dart';
import '/riverpod/logic/chat_service.dart';

class ChatDeleteDialog {
  static Future<void> show({
    required BuildContext context,
    required ChatService chatService,
    required String chatId,
  }) async {
    final theme = Theme.of(context);

    return showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: const Text("Delete Chat"),

          content: const Text(
            "Are you sure you want to delete this chat? This action cannot be undone.",
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await chatService.deleteChat(chatId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
