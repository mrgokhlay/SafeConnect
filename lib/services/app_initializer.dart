import 'package:firebase_auth/firebase_auth.dart';
import '../services/presence_service.dart';

class AppInitializer {
  AppInitializer._();

  static void init() {
    _listenAuthAndPresence();
    _checkExistingUser(); // 🔥 IMPORTANT FIX
  }

  static void _listenAuthAndPresence() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await PresenceService.instance.initPresence();
      } else {
        await PresenceService.instance.goOffline();
      }
    });
  }

  // 🔥 THIS FIXES YOUR ISSUE
  static Future<void> _checkExistingUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await PresenceService.instance.initPresence();
    }
  }
}
