import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference? _statusRef;
  StreamSubscription? _connectionSub;
  Timer? _heartbeat;

  String? get _uid => _auth.currentUser?.uid;

  // ===============================
  // 🟢 INIT PRESENCE (FIXED + STABLE)
  // ===============================
  Future<void> initPresence() async {
    final uid = _uid;
    if (uid == null) return;

    _statusRef = _db.child('status/$uid');

    final connectedRef = _db.child('.info/connected');

    // cancel old listeners
    await _connectionSub?.cancel();
    _heartbeat?.cancel();

    _connectionSub = connectedRef.onValue.listen((event) async {
      final connected = event.snapshot.value == true;

      if (!connected || _statusRef == null) return;

      try {
        // 🔥 always re-attach onDisconnect
        await _statusRef!.onDisconnect().set({
          'isOnline': false,
          'lastChanged': ServerValue.timestamp,
        });

        // 🔥 mark online immediately
        await _statusRef!.set({
          'isOnline': true,
          'lastChanged': ServerValue.timestamp,
        });

        // ==========================
        // 🔥 HEARTBEAT (FIX OFFLINE BUG)
        // ==========================
        _heartbeat?.cancel();
        _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) async {
          final u = _uid;
          if (u == null) return;

          await _db.child('status/$u').update({
            'isOnline': true,
            'lastChanged': ServerValue.timestamp,
          });
        });
      } catch (e) {
        print("Presence error: $e");
      }
    });
  }

  // ===============================
  // 🔴 STREAM FOR UI
  // ===============================
  Stream<bool> isOnlineStream(String uid) {
    return _db.child('status/$uid').onValue.map((event) {
      final data = event.snapshot.value;

      if (data is Map) {
        return data['isOnline'] == true;
      }
      return false;
    });
  }

  // ===============================
  // 🔴 MANUAL OFFLINE
  // ===============================
  Future<void> goOffline() async {
    final uid = _uid;
    if (uid == null) return;

    _heartbeat?.cancel();

    await _db.child('status/$uid').set({
      'isOnline': false,
      'lastChanged': ServerValue.timestamp,
    });
  }

  // ===============================
  // 🚪 LOGOUT SAFE
  // ===============================
  Future<void> onLogout() async {
    await goOffline();
    await _auth.signOut();
  }

  // ===============================
  // 🧹 CLEANUP (IMPORTANT)
  // ===============================
  Future<void> dispose() async {
    await _connectionSub?.cancel();
    _heartbeat?.cancel();
  }
}
