import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/messaging_logic.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverId;
  final TextEditingController controller;
  final ScrollController scrollController;

  const ChatInputBar({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.controller,
    required this.scrollController,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final FocusNode _focusNode = FocusNode();

  void _scrollToBottom() {
    if (widget.scrollController.hasClients) {
      widget.scrollController.jumpTo(
        widget.scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagingService = MessagingService();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✍️ TEXT INPUT ONLY
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // 🚀 SEND BUTTON
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () async {
                  final text = widget.controller.text.trim();
                  if (text.isEmpty) return;

                  // instant UI update
                  widget.controller.clear();
                  _focusNode.unfocus();
                  _scrollToBottom();

                  try {
                    await messagingService.sendMessage(
                      chatId: widget.chatId,
                      text: text,
                      otherUserId: widget.receiverId,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Message not sent")),
  );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
