import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatServiceProvider = Provider((ref) => ChatService());

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  // =========================
  // CHAT ID
  // =========================
  String generateChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // =========================
  // GET CHATS (OPTIMIZED + SAFE)
  // =========================
  Stream<List<QueryDocumentSnapshot>> getChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.where((doc) {
            final data = doc.data();

            final deletedFor = List<String>.from(data['deletedFor'] ?? []);

            // 🔥 safety: avoid null crashes
            return !deletedFor.contains(uid);
          }).toList();

          // 🔥 sort by latest activity (WhatsApp-like)
          chats.sort((a, b) {
            final aTime =
                (a['lastMessageTime'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
            final bTime =
                (b['lastMessageTime'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
            return bTime.compareTo(aTime);
          });

          return chats;
        });
  }

  // =========================
  // CREATE OR GET CHAT (SAFE + CLEAN)
  // =========================
  Future<String> createOrGetChat(String otherId) async {
    final chatId = generateChatId(uid, otherId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        'participants': [uid, otherId],
        'createdAt': FieldValue.serverTimestamp(),

        'lastMessage': '',
        'lastMessageTime': null,
        'lastMessageSenderId': null,

        'unreadCount': {uid: 0, otherId: 0},

        'deletedFor': [],
      });
    } else {
      final data = doc.data() ?? {};
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);

      if (deletedFor.contains(uid)) {
        await chatRef.update({
          'deletedFor': FieldValue.arrayRemove([uid]),
        });
      }
    }

    await resetUnread(chatId);
    return chatId;
  }

  // =========================
  // RESET UNREAD (FIXED)
  // =========================
  Future<void> resetUnread(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$uid': 0,
    });
  }

  // =========================
  // DELETE CHAT (SAFE + NO DATA LOSS)
  // =========================
  Future<void> deleteChat(String chatId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    final snapshot = await chatRef.collection('messages').get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'deletedFor': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    // 🔥 IMPORTANT FIX:
    // DO NOT erase global chat preview (prevents UI bugs)
    await chatRef.set({
      'deletedFor': FieldValue.arrayUnion([uid]),
      'unreadCount.$uid': 0,
    }, SetOptions(merge: true));
  }
}
