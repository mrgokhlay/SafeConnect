import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ================= CHAT UNREAD =================
final chatUnreadCountProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: uid)
      .snapshots()
      .map((snapshot) {
        int total = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data();

          final Map<String, dynamic> unread = Map<String, dynamic>.from(
            data['unreadCount'] ?? {},
          );

          final value = unread[uid];

          if (value is int) {
            total += value;
          } else if (value is num) {
            total += value.toInt();
          }
        }

        return total;
      });
});

// ================= REQUEST BADGE (FIXED) =================
final requestBadgeProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('chat_requests')
      .where('receiverId', isEqualTo: uid)
      .snapshots()
      .map((snap) {
        int count = 0;

        for (final doc in snap.docs) {
          final data = doc.data();

          if (data['status'] == 'pending') {
            count++;
          }
        }

        return count;
      });
});
