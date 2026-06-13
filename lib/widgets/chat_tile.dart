import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  final String username;
  final String lastMsg;

  final DateTime? lastMessageTime;

  final bool isOnline;
  final int unread;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatTile({
    super.key,
    required this.username,
    required this.lastMsg,
    required this.lastMessageTime,
    required this.isOnline,
    required this.unread,
    required this.onTap,
    required this.onLongPress,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(time.year, time.month, time.day);

    if (msgDay == today) {
      return DateFormat('hh:mm a').format(time);
    }

    if (msgDay == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    }

    return DateFormat('dd/MM').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final timeText = _formatTime(lastMessageTime);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),

      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),

        child: Row(
          children: [
            // ================= AVATAR =================
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : "U",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                      border: Border.all(color: theme.cardColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // ================= NAME + MESSAGE =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ================= TIME + UNREAD =================
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeText.isNotEmpty)
                  Text(
                    timeText,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),

                const SizedBox(height: 6),

                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$unread",
                      style: const TextStyle(
                        color: Color.fromARGB(255, 19, 4, 92),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
