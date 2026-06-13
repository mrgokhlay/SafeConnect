import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../services/presence_service.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
      (ref) => AuthController(FirebaseAuth.instance),
    );

class AuthController extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth auth;

  AuthController(this.auth) : super(const AsyncData(null));

  User? get currentUser => auth.currentUser;

  // =========================
  // LOGIN
  // =========================
  Future<void> login({required String email, required String password}) async {
    final mail = email.trim();
    final pass = password.trim();

    if (mail.isEmpty || pass.isEmpty) {
      state = AsyncError("Email & Password required", StackTrace.current);
      return;
    }

    state = const AsyncLoading();

    try {
      // 1. LOGIN
      await auth.signInWithEmailAndPassword(
        email: mail.toLowerCase(),
        password: pass,
      );

      final user = auth.currentUser;

      if (user != null) {
        // 2. START PRESENCE SYSTEM (IMPORTANT)

        // 3. UPDATE FCM TOKEN
        final token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
        }
      }

      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(_mapError(e), StackTrace.current);
    } catch (_) {
      state = AsyncError("Something went wrong", StackTrace.current);
    }
  }

  // =========================
  // POST LOGIN FLOW
  // =========================
  Future<String> postLoginFlow() async {
    final user = auth.currentUser;

    if (user == null) return "login";

    await user.reload();

    final updated = auth.currentUser;
    if (updated == null) return "login";

    // EMAIL VERIFY
    if (!updated.emailVerified) {
      await auth.signOut();
      return "verify_email";
    }

    // PROFILE CHECK
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(updated.uid)
        .get();

    final username = doc.data()?['username'];

    if (username == null || username.toString().isEmpty) {
      return "username";
    }

    return "chat";
  }

  // =========================
  // FORGOT PASSWORD
  // =========================
  Future<void> forgotPassword(String email) async {
    final mail = email.trim();

    if (mail.isEmpty) {
      state = AsyncError("Please enter your email first", StackTrace.current);
      return;
    }

    state = const AsyncLoading();

    try {
      await auth.sendPasswordResetEmail(email: mail.toLowerCase());
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(_mapError(e), StackTrace.current);
    } catch (_) {
      state = AsyncError("Something went wrong", StackTrace.current);
    }
  }

  // =========================
  // LOGOUT (CLEAN + SAFE)
  // =========================
  Future<void> logout() async {
    state = const AsyncLoading();

    final user = auth.currentUser;

    try {
      if (user != null) {
        // 1. OFFLINE VIA PRESENCE SERVICE
        await PresenceService.instance.goOffline();

        // 2. REMOVE FCM TOKEN (optional safe delete)
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'fcmToken': FieldValue.delete()});
        } catch (_) {
          // fallback
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': null}, SetOptions(merge: true));
        }
      }

      // 3. SIGN OUT ALWAYS
      await auth.signOut();

      state = const AsyncData(null);
    } catch (e) {
      // force logout even on failure
      try {
        await auth.signOut();
      } catch (_) {}

      state = AsyncError("Logout failed", StackTrace.current);
    }
  }

  // =========================
  // ERROR MAPPER
  // =========================
  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No account found with this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'network-request-failed':
        return "No internet connection.";
      default:
        return e.message ?? "Authentication failed";
    }
  }
}
