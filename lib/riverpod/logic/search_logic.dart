import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) return [];

    final normalizedQuery = trimmed.toLowerCase();

    final snapshot = await _firestore
        .collection('users')
        .where('usernameLower', isGreaterThanOrEqualTo: normalizedQuery)
        .where('usernameLower', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      final image = (data['profileImage'] ?? '').toString().trim();

      return {
        'uid': doc.id,
        'username': data['username'] ?? '',
        'email': data['email'] ?? '',
        'profileImage': image.isEmpty ? null : image,
        'isMe': doc.id == currentUserId,
      };
    }).toList();
  }
}
