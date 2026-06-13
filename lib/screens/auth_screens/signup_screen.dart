import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../riverpod/features/signup_controler.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // =========================
  // COLORS
  // =========================
  static const bg = Color(0xFF070B14); // midnight black
  static const card = Color(0xFF111827); // dark navy grey
  static const accent = Color(0xFF8B5CF6); // soft violet

  @override
  void initState() {
    super.initState();

    ref.listenManual(authControllerProvider, (previous, next) {
      if (!mounted) return;

      // ERROR
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(next.error.toString()),
          ),
        );
      }

      // SUCCESS
      if (next is AsyncData<void> && previous is AsyncLoading) {
        Future.microtask(() {
          context.go('/verify_email');
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================
  // INPUT DESIGN
  // =========================
  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1A2333),

      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),

      prefixIcon: Icon(icon, color: accent),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(28),

                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: accent.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // =========================
                    // TOP GREEN DOT
                    // =========================
                    const SizedBox(height: 24),

                    const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Join SafeConnect securely",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),

                    const SizedBox(height: 36),

                    // =========================
                    // EMAIL
                    // =========================
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),

                      decoration: _input("Email", Icons.email_outlined),

                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Email required"
                          : null,
                    ),

                    const SizedBox(height: 18),

                    // =========================
                    // PASSWORD
                    // =========================
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),

                      decoration: _input("Password", Icons.lock_outline)
                          .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white54,
                              ),

                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),

                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Password required"
                          : null,
                    ),

                    const SizedBox(height: 28),

                    // =========================
                    // CONTINUE BUTTON
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton(
                        onPressed: authState is AsyncLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signUp(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text
                                            .trim(),
                                      );
                                }
                              },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),

                        child: authState is AsyncLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              )
                            : const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // LOGIN NAVIGATION
                    // =========================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white60),
                        ),

                        TextButton(
                          onPressed: () => context.go('/login'),

                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
