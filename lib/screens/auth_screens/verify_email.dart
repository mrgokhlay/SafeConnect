import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  // =========================
  // COLORS
  // =========================
  static const bg = Color(0xFF070B14);
  static const card = Color(0xFF111827);
  static const accent = Color(0xFF8B5CF6);

  Future<void> _goToLogin(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (_) {}

    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),

              child: Container(
                padding: EdgeInsets.all(width < 360 ? 22 : 28),

                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(30),

                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: accent.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // =========================
                    // ICON
                    // =========================
                    Container(
                      width: 95,
                      height: 95,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // ignore: deprecated_member_use
                        color: accent.withOpacity(0.12),

                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: accent.withOpacity(0.35),
                          width: 1.5,
                        ),
                      ),

                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        size: 46,
                        color: accent,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =========================
                    // TITLE
                    // =========================
                    const Text(
                      "Verify Your Email",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =========================
                    // DESCRIPTION
                    // =========================
                    const Text(
                      "We’ve sent a verification link to your email address.\nPlease verify your account before logging in.",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =========================
                    // INFO BOX
                    // =========================
                    Container(
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2333),
                        borderRadius: BorderRadius.circular(18),

                        // ignore: deprecated_member_use
                        border: Border.all(color: accent.withOpacity(0.18)),
                      ),

                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: accent,
                            size: 20,
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              "If you can't find the email, check your Spam or Promotions folder.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    // =========================
                    // BUTTON
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      height: 56,

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),

                        onPressed: () => _goToLogin(context),

                        child: const Text(
                          "Back to Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "SafeConnect",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
