import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final messagingServiceProvider = Provider((ref) => MessagingService());

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  // =========================
  // GET MESSAGES (SAFE ORDERING)
  // =========================
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .limit(200)
        .snapshots();
  }

  // =========================
  // SEND MESSAGE (PRODUCTION SAFE)
  // =========================
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String otherUserId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    await _firestore.runTransaction((tx) async {
      tx.set(msgRef, {
        'text': trimmed,
        'senderId': uid,
        'receiverId': otherUserId,
        'sentAt': FieldValue.serverTimestamp(),
        'deletedFor': [],
        'seen': false,
      });

      tx.update(chatRef, {
        'lastMessage': trimmed,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': uid,

        // unread update (critical fix)
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    });

    await _sendNotification(
      receiverId: otherUserId,
      message: trimmed,
      chatId: chatId,
    );
  }

  // =========================
  // MARK AS SEEN (FIX UNREAD ACCURACY)
  // =========================
  Future<void> markAsSeen(String chatId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    final snapshot = await chatRef
        .collection('messages')
        .where('receiverId', isEqualTo: uid)
        .where('seen', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'seen': true});
    }

    batch.update(chatRef, {'unreadCount.$uid': 0});

    await batch.commit();
  }

  // =========================
  // DELETE MESSAGES (OPTIMIZED)
  // =========================
  Future<void> deleteMessages({
    required String chatId,
    required List<String> messageIds,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final batch = _firestore.batch();

    // 1. mark selected messages deleted for me
    for (final id in messageIds) {
      final msgRef = chatRef.collection('messages').doc(id);

      batch.set(msgRef, {
        'deletedFor': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    // 2. recompute last visible message (LIMITED for performance)
    final snapshot = await chatRef
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .get();

    String? lastText;
    Timestamp? lastTime;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);

      if (!deletedFor.contains(uid)) {
        lastText = data['text'];
        lastTime = data['sentAt'];
        break;
      }
    }

    // 3. update chat safely
    if (lastText != null && lastTime != null) {
      await chatRef.update({
        'lastMessage': lastText,
        'lastMessageTime': lastTime,
      });
    } else {
      await chatRef.update({
        'lastMessage': 'No messages yet',
        'lastMessageTime': null,
      });
    }
  }

  // =========================
  // NOTIFICATION (SAFE)
  // =========================
  Future<void> _sendNotification({
    required String receiverId,
    required String message,
    required String chatId,
  }) async {
    try {
      await http.post(
        Uri.parse(
          "https://safeconnect-production.up.railway.app/message-notification",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "receiverId": receiverId,
          "message": message,
          "chatId": chatId,
          "senderId": uid,
        }),
      );
    } catch (_) {
      // silent fail (don’t break chat)
    }
  }
}
