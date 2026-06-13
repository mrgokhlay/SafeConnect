import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safeconnect/services/presence_service.dart';
import '../logic/messaging_logic.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String username;
  final String userId;
  final String chatId;

  const ChatAppBar({
    super.key,
    required this.username,
    required this.userId,
    required this.chatId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagingService = MessagingService();

    return AppBar(
      titleSpacing: 0,
      title: StreamBuilder<bool>(
        stream: PresenceService.instance.isOnlineStream(userId),
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? false;

          return Row(
            children: [
              CircleAvatar(
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : "?",
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(username),
                  Text(
                    isOnline ? "Online" : "Offline",
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
