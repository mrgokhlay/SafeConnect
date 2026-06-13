// riverpod/logic/requests_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../logic/chat_service.dart';

final requestsServiceProvider = Provider<RequestsService>(
  (ref) => RequestsService(),
);

class RequestsService {
  final _firestore = FirebaseFirestore.instance;

  // Current logged-in user
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  // ===============================
  // 📩 INCOMING REQUESTS
  // ===============================
  Stream<QuerySnapshot> incomingRequests() {
    return _firestore
        .collection('chat_requests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ===============================
  // 🔄 REAL-TIME RELATIONSHIP STATUS
  // ===============================
  Stream<String> relationshipStream(String otherUserId) async* {
    final docRef = _firestore.collection('chat_requests');
    final chatRef = _firestore.collection('chats');

    yield* Stream.periodic(const Duration(milliseconds: 500)).asyncMap((
      _,
    ) async {
      // 1️⃣ Connected
      final chats = await chatRef
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var chat in chats.docs) {
        final participants = List<String>.from(chat['participants']);

        if (participants.contains(otherUserId)) {
          return "connected";
        }
      }

      // 2️⃣ Pending Sent
      final sent = await docRef
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (sent.docs.isNotEmpty) {
        return "pending_sent";
      }

      // 3️⃣ Pending Received
      final received = await docRef
          .where('receiverId', isEqualTo: currentUserId)
          .where('senderId', isEqualTo: otherUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (received.docs.isNotEmpty) {
        return "pending_received";
      }

      return "none";
    });
  }

  // ===============================
  // 🚀 SEND FRIEND REQUEST
  // ===============================
  Future<void> sendRequest(String receiverId) async {
    // Prevent duplicate request
    final exists = await _firestore
        .collection('chat_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (exists.docs.isNotEmpty) return;

    // Save request in Firestore
    await _firestore.collection('chat_requests').add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Get sender info
    final senderDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    final senderName = senderDoc.data()?['username'] ?? "Someone";

    // Send REAL push notification
    await _sendPushNotification(receiverId: receiverId, senderName: senderName);
  }

  // ===============================
  // ❌ CANCEL REQUEST
  // ===============================
  Future<void> cancelRequest(String receiverId) async {
    final snapshot = await _firestore
        .collection('chat_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ===============================
  // 🔥 REAL PUSH NOTIFICATION
  // ===============================
  Future<void> _sendPushNotification({
    required String receiverId,
    required String senderName,
  }) async {
    try {
      final url = Uri.parse(
        "https://safeconnect-production.up.railway.app/friend-request",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"receiverId": receiverId, "senderName": senderName}),
      );

      print("🚀 Notification Response: ${response.body}");
    } catch (e) {
      print("❌ Push Notification Error: $e");
    }
  }

  // ===============================
  // ✅ ACCEPT REQUEST
  // ===============================
  Future<String> acceptRequest(String requestId, String senderId) async {
    await _firestore.collection('chat_requests').doc(requestId).update({
      'status': 'accepted',
    });

    final chatId = await ChatService().createOrGetChat(senderId);

    // 🔥 SEND ACCEPT NOTIFICATION (ONLY ONCE)
    await _sendAcceptNotification(receiverId: senderId);

    return chatId;
  }

  Future<void> _sendAcceptNotification({required String receiverId}) async {
    try {
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      final username = currentUserDoc.data()?['username'] ?? "Someone";

      final url = Uri.parse(
        "https://safeconnect-production.up.railway.app/request-accepted",
      );

      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"receiverId": receiverId, "username": username}),
      );
    } catch (e) {
      print("❌ Accept Notification Error: $e");
    }
  }

  // ===============================
  // ❌ REJECT REQUEST
  // ===============================
  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('chat_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  // ===============================
  // 👤 GET SENDER INFO
  // ===============================
  Future<DocumentSnapshot> getSenderInfo(String senderId) async {
    return await _firestore.collection('users').doc(senderId).get();
  }
}
