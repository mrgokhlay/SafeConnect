import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
      (ref) => AuthController(),
    );

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncData(null));

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUp({required String email, required String password}) async {
    final mail = email.trim();
    final pass = password.trim();

    // ================= VALIDATION =================
    if (mail.isEmpty) {
      state = AsyncError("Email cannot be empty", StackTrace.current);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(mail)) {
      state = AsyncError("Invalid email format", StackTrace.current);
      return;
    }

    if (pass.isEmpty) {
      state = AsyncError("Password cannot be empty", StackTrace.current);
      return;
    }

    if (pass.length < 8) {
      state = AsyncError(
        "Password must be at least 8 characters",
        StackTrace.current,
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      state = AsyncError("Add uppercase letter", StackTrace.current);
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(pass)) {
      state = AsyncError("Add lowercase letter", StackTrace.current);
      return;
    }

    if (!RegExp(r'[0-9]').hasMatch(pass)) {
      state = AsyncError("Add number", StackTrace.current);
      return;
    }

    if (!RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(pass)) {
      state = AsyncError("Add special character", StackTrace.current);
      return;
    }

    // ================= FIREBASE =================
    state = const AsyncLoading();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: mail.toLowerCase(),
        password: pass,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception("User creation failed");
      }

      await user.sendEmailVerification();

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'username': null,
      });

      // 🔥 IMPORTANT: trigger success EVENT
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(_mapError(e), StackTrace.current);
    } catch (_) {
      state = AsyncError(
        "Something went wrong. Try again.",
        StackTrace.current,
      );
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Email already exists. Please login.";
      case 'weak-password':
        return "Weak password.";
      case 'invalid-email':
        return "Invalid email.";
      case 'network-request-failed':
        return "No internet connection.";
      default:
        return e.message ?? "Signup failed";
    }
  }
}
