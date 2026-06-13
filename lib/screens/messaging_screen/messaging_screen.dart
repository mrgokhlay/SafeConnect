import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'logic/messaging_logic.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/messaging_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/date_header.dart';

class MessagingScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUsername;

  const MessagingScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  int _lastMessageCount = 0;

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(messagingServiceProvider).markAsSeen(widget.chatId);
  });
}

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final messagingService = ref.read(messagingServiceProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: ChatAppBar(
        username: widget.otherUsername,
        userId: widget.otherUserId,
        chatId: widget.chatId,
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagingService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.length != _lastMessageCount) {
                  _lastMessageCount = docs.length;
                  _scrollToBottom();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final messageId = docs[index].id;

                    final deletedFor = List<String>.from(
                      data['deletedFor'] ?? [],
                    );

                    final isDeletedForMe =
                        currentUid != null && deletedFor.contains(currentUid);

                    if (isDeletedForMe) {
                      return const SizedBox.shrink();
                    }

                    final isMe = data['senderId'] == currentUid;

                    // =========================
                    // DATE PARSING ONLY (NO FORMAT LOGIC HERE)
                    // =========================
                    DateTime? date;
                    final sentAt = data['sentAt'];

                    if (sentAt is Timestamp) {
                      date = sentAt.toDate();
                    }

                    DateTime? prevDate;

                    if (index > 0) {
                      final prevData =
                          docs[index - 1].data() as Map<String, dynamic>;

                      final prevSentAt = prevData['sentAt'];

                      if (prevSentAt is Timestamp) {
                        prevDate = prevSentAt.toDate();
                      }
                    }

                    final showHeader =
                        index == 0 ||
                        (date != null &&
                            prevDate != null &&
                            !_isSameDay(date, prevDate));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader && date != null) DateHeader(date: date),

                        MessageBubble(
                          text: data['text'] ?? '',
                          isMe: isMe,
                          messageId: messageId,
                          sentAt: data['sentAt'],
                          isSelected: false,
                          seen: data['seen'] ?? false,
                          onLongPress: () {
                            showMenu(
                              context: context,
                              position: const RelativeRect.fromLTRB(
                                100,
                                200,
                                0,
                                0,
                              ),
                              items: const [
                                PopupMenuItem(
                                  value: "copy",
                                  child: Text("Copy"),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text("Delete for me"),
                                ),
                              ],
                            ).then((result) {
                              if (result == "copy") {
                                Clipboard.setData(
                                  ClipboardData(text: data['text'] ?? ''),
                                );
                              }

                              if (result == "delete") {
                                ref
                                    .read(messagingServiceProvider)
                                    .deleteMessages(
                                      chatId: widget.chatId,
                                      messageIds: [messageId],
                                    );
                              }
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          ChatInputBar(
            chatId: widget.chatId,
            receiverId: widget.otherUserId,
            controller: _controller,
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }
}
