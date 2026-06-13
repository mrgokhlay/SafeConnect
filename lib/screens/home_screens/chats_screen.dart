import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:safeconnect/screens/messaging_screen/widgets/chat_delete_dialouge.dart';
import 'package:safeconnect/widgets/chat_app_bar.dart';
import 'package:safeconnect/widgets/chat_tile.dart';
import 'package:safeconnect/utils/chat_formatters.dart';

import '../../riverpod/logic/chat_service.dart';
import '../../services/presence_service.dart';
import 'package:safeconnect/widgets/connect_dialouge.dart';

final userChatsProvider = StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChats();
});

/// ✅ SAFE CAST HELPER (IMPORTANT)
Map<String, dynamic> safeMap(dynamic data) {
  return Map<String, dynamic>.from(data ?? {});
}

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final Map<String, String> _usernameCache = {};

  Future<String> _getUsername(String uid) async {
    if (_usernameCache.containsKey(uid)) return _usernameCache[uid]!;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    final name =
        data?['username'] as String? ?? data?['displayName'] as String? ?? '';

    _usernameCache[uid] = name;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.read(chatServiceProvider);
    final chatsAsync = ref.watch(userChatsProvider);

    final uid = chatService.uid;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          ConnectDialog.show(context, chatService.createOrGetChat);
        },
      ),

      appBar: const ChatsAppBar(),

      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          chats.sort((a, b) {
            final aData = safeMap(a.data());
            final bData = safeMap(b.data());

            final aT = aData['lastMessageTime'] as Timestamp?;
            final bT = bData['lastMessageTime'] as Timestamp?;

            return (bT ?? Timestamp(0, 0)).compareTo(aT ?? Timestamp(0, 0));
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = safeMap(chat.data());

              final participants = List<String>.from(
                data['participants'] ?? [],
              );

              final otherUserId = participants.firstWhere(
                (e) => e != uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox();
              final deletedFor = List<String>.from(data['deletedFor'] ?? []);
              final rawMsg = data['lastMessage'];
              final lastMsg = deletedFor.contains(uid)
                  ? "No messages yet"
                  : (rawMsg == null || rawMsg.toString().trim().isEmpty)
                  ? "No messages yet"
                  : rawMsg.toString();

              final unreadMap = Map<String, dynamic>.from(
                data['unreadCount'] ?? {},
              );

              final unread = unreadMap[uid] ?? 0;

              return FutureBuilder<String>(
                future: _getUsername(otherUserId),
                builder: (context, snap) {
                  final username = snap.data ?? "Loading...";

                  return StreamBuilder<bool>(
                    stream: PresenceService.instance.isOnlineStream(
                      otherUserId,
                    ),
                    builder: (context, onlineSnap) {
                      final isOnline = onlineSnap.data ?? false;

                      return ChatTile(
                        username: username,
                        lastMsg: lastMsg,

                        lastMessageTime: ChatFormatters.getLastMessageTime(
                          data,
                        ),

                        isOnline: isOnline,
                        unread: unread,

                        onTap: () async {
                          context.push(
                            '/message',
                            extra: {
                              'chatId': chat.id,
                              'otherUserId': otherUserId,
                              'otherUsername': username,
                            },
                          );

                          await chatService.resetUnread(chat.id);
                        },

                        onLongPress: () {
                          ChatDeleteDialog.show(
                            context: context,
                            chatService: chatService,
                            chatId: chat.id,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
