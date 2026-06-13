import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safeconnect/firebase_options.dart';
import 'package:safeconnect/routes/app_routes.dart';
import 'package:safeconnect/services/app_initializer.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

/// ===============================
/// FIREBASE INIT
/// ===============================
Future<void> initFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// ===============================
/// BACKGROUND HANDLER
/// ===============================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initFirebase();
}

/// ===============================
/// MAIN
/// ===============================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initFirebase();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 🔥 INIT APP LIFECYCLE SYSTEM (presence, auth restore)
  AppInitializer.init();

  runApp(const ProviderScope(child: SafeConnectApp()));
}

/// ===============================
/// APP ROOT
/// ===============================
class SafeConnectApp extends ConsumerStatefulWidget {
  const SafeConnectApp({super.key});

  @override
  ConsumerState<SafeConnectApp> createState() => _SafeConnectAppState();
}

/// ===============================
/// APP STATE (FCM ONLY)
/// ===============================
class _SafeConnectAppState extends ConsumerState<SafeConnectApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSub;

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  /// ===============================
  /// FCM SETUP
  /// ===============================
  Future<void> _initFCM() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    await _saveToken(token);

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("📩 Foreground: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("🔔 Notification clicked");
    });
  }

  /// Save / Update FCM token in Firestore
  Future<void> _saveToken(String? token) async {
    final user = _auth.currentUser;
    if (user == null || token == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint("✅ FCM token saved");
  }

  /// Dispose
  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}
