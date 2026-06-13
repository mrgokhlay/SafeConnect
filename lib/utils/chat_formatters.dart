import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatFormatters {
  static String formatTime(Timestamp? t) {
    if (t == null) return '';
    return DateFormat('hh:mm a').format(t.toDate());
  }

  static String formatChatDate(Timestamp? t) {
    if (t == null) return '';

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final msg = t.toDate();
    final msgDate = DateTime(msg.year, msg.month, msg.day);

    if (msgDate == today) return "Today";
    if (msgDate == yesterday) return "Yesterday";

    return DateFormat('dd/MM/yyyy').format(msgDate);
  }

  /// ✅ CLEAN VERSION (ONLY TRUST CHAT DOC)
  static String getLastMessage(Map data) {
    final last = data['lastMessage'];

    if (last == null || last.toString().trim().isEmpty) {
      return "No messages yet";
    }

    return last.toString();
  }

  static int getUnreadCount(Map data, String uid) {
    final map = (data['unreadCount'] ?? {}) as Map;
    return (map[uid] ?? 0) as int;
  }

  static DateTime? getLastMessageTime(Map data) {
    final t = data['lastMessageTime'];
    if (t is Timestamp) return t.toDate();
    return null;
  }
}
