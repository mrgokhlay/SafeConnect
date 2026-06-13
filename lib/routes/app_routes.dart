import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth_screens/login_screen.dart';
import '../screens/auth_screens/signup_screen.dart';
import '../screens/auth_screens/username_screen.dart';
import '../screens/auth_screens/verify_email.dart';

import '../screens/home_screens/chats_screen.dart';
import '../screens/home_screens/requests_screen.dart';
import '../screens/home_screens/search_screen.dart';
import '../screens/home_screens/ai_screen.dart';
import '../screens/home_screens/profile_screen.dart';

import '../screens/messaging_screen/messaging_screen.dart';
import '../widgets/navbar_widget.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',

    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.userChanges(),
    ),

    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      final isLogin = location == '/login';
      final isSignup = location == '/signup';
      final isVerify = location == '/verify_email';
      final isUsername = location == '/username';

      // ===============================
      // 1. NO USER → AUTH ONLY
      // ===============================
      if (user == null) {
        if (isLogin || isSignup) return null;
        return '/login';
      }

      final verified = user.emailVerified;

      // ===============================
      // 2. EMAIL NOT VERIFIED → FORCE VERIFY
      // ===============================
      if (!verified) {
        if (isVerify) return null;
        return '/verify_email';
      }

      // ===============================
      // 3. PROFILE CHECK (USERNAME REQUIRED)
      // ===============================
      final needsUsername =
          user.displayName == null || user.displayName!.trim().isEmpty;

      if (needsUsername) {
        if (isUsername) return null;
        return '/username';
      }

      // ===============================
      // 4. USER READY → ENTER APP
      // ===============================
      final isAuthScreen = isLogin || isSignup || isVerify || isUsername;

      if (isAuthScreen) {
        return '/chat';
      }

      return null;
    },

    routes: [
      // =========================
      // AUTH SCREENS
      // =========================
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/username', builder: (_, _) => const UsernameScreen()),
      GoRoute(
        path: '/verify_email',
        builder: (_, _) => const EmailVerificationScreen(),
      ),

      // =========================
      // MAIN APP (WITH BOTTOM NAV)
      // =========================
      ShellRoute(
        builder: (context, state, child) {
          final hideNavBar = state.matchedLocation == '/ai';
          return Scaffold(
            body: child,
            bottomNavigationBar: hideNavBar ? null : const SafeConnectNavBar(),
          );
        },
        routes: [
          GoRoute(path: '/chat', builder: (_, _) => const ChatsScreen()),
          GoRoute(path: '/requests', builder: (_, _) => const RequestsScreen()),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),

      // =========================
      // CHAT DETAILS SCREEN
      // =========================
      GoRoute(path: '/ai', builder: (context, state) => const AiScreen()),
      GoRoute(
        path: '/message',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return MessagingScreen(
            chatId: extra['chatId'],
            otherUserId: extra['otherUserId'],
            otherUsername: extra['otherUsername'],
          );
        },
      ),
    ],

    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;

  GoRouterRefreshStream(Stream stream) {
    _sub = stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
