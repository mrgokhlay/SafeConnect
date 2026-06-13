import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String messageId;
  final bool isSelected;
  final VoidCallback onLongPress;
  final Timestamp? sentAt;

  final bool seen; // ✅ ADD THIS

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.messageId,
    required this.isSelected,
    required this.onLongPress,
    this.sentAt,
    this.seen = false,
  });

  String _formatTime(Timestamp? t) {
    if (t == null) return '';
    return DateFormat('hh:mm a').format(t.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: isMe ? theme.colorScheme.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 3),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 5),

                  // ================= TICKS =================
                  if (isMe)
                    Icon(
                      seen ? Icons.done_all : Icons.done,
                      size: 14,
                      color: seen ? Colors.blue : Colors.white70,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
