import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';

final usernameControllerProvider =
    StateNotifierProvider<UsernameController, UsernameState>(
      (ref) => UsernameController(),
    );

class UsernameState {
  final bool isLoading;
  final String? error;

  UsernameState({this.isLoading = false, this.error});
}

class UsernameController extends StateNotifier<UsernameState> {
  UsernameController() : super(UsernameState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUsername(String username) async {
    username = username.trim();

    /// Validation
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9._]{2,19}$');
    final consecutive = RegExp(r'([_.])\1');

    if (username.isEmpty) {
      state = UsernameState(error: "Username cannot be empty");
      return;
    }

    if (!regex.hasMatch(username)) {
      state = UsernameState(
        error:
            "Username must start with a letter, 3-20 chars, letters, numbers, dot or underscore only",
      );
      return;
    }

    if (consecutive.hasMatch(username)) {
      state = UsernameState(
        error: "Username cannot have consecutive dots or underscores",
      );
      return;
    }

    if (username.endsWith('.') || username.endsWith('_')) {
      state = UsernameState(
        error: "Username cannot end with dot or underscore",
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      state = UsernameState(error: "No logged-in user found");
      return;
    }

    state = UsernameState(isLoading: true);

    try {
      /// 🔥 Check if username already exists
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (query.docs.isNotEmpty) {
        state = UsernameState(error: "Username already taken");
        return;
      }

      /// 🔥 SAFE WRITE (set + merge)
      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'usernameLower': username.toLowerCase(), // useful for search later
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      /// 🔥 Update Firebase Auth display name
      await user.updateDisplayName(username);

      state = UsernameState(isLoading: false);
    } on FirebaseException catch (e) {
      state = UsernameState(error: e.message);
    } catch (e) {
      state = UsernameState(error: e.toString());
    }
  }
}
