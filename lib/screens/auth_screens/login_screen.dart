import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../riverpod/features/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // =========================
  // COLORS
  // =========================
  static const bg = Color(0xFF070B14);
  static const card = Color(0xFF111827);
  static const accent = Color(0xFF8B5CF6);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================
  // LOGIN
  // =========================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);

    await controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    final state = ref.read(authControllerProvider);

    if (state is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(state.error.toString()),
        ),
      );
      return;
    }

    final route = await controller.postLoginFlow();

    if (!mounted) return;

    switch (route) {
      case "username":
        context.go('/username');
        break;

      case "chat":
        context.go('/chat');
        break;

      case "verify_email":
        context.go('/verify_email');
        break;

      default:
        context.go('/login');
    }
  }

  // =========================
  // FORGOT PASSWORD
  // =========================
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter your email first")));
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);

    await controller.forgotPassword(email);

    if (!mounted) return;

    final state = ref.read(authControllerProvider);

    if (state is AsyncError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error.toString())));
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: card,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

        title: const Text(
          "Reset Email Sent",
          style: TextStyle(color: Colors.white),
        ),

        content: Text(
          "Password reset link sent to:\n$email",
          style: const TextStyle(color: Colors.white70),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text("OK", style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  // =========================
  // INPUT DESIGN
  // =========================
  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1A2333),

      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),

      prefixIcon: Icon(icon, color: accent),

      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: accent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),

              child: Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(30),

                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: accent.withOpacity(0.12),
                      blurRadius: 28,
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
                      // BRANDING
                      // =========================
                      const SizedBox(height: 4),

                      const Text(
                        "Welcome to",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 0.4,
                        ),
                      ),

                      const SizedBox(height: 4),

                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D5DFB)],
                          ).createShader(bounds);
                        },

                        child: Text(
                          "SafeConnect",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width < 350 ? 28 : 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Secure messaging experience",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),

                      const SizedBox(height: 30),

                      // =========================
                      // EMAIL
                      // =========================
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,

                        style: const TextStyle(color: Colors.white),

                        decoration: _dec("Email", Icons.email_outlined),

                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Email required";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // =========================
                      // PASSWORD
                      // =========================
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,

                        style: const TextStyle(color: Colors.white),

                        decoration: _dec("Password", Icons.lock_outline)
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

                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Password required";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      // =========================
                      // FORGOT PASSWORD
                      // =========================
                      Align(
                        alignment: Alignment.centerRight,

                        child: TextButton(
                          onPressed: _forgotPassword,

                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =========================
                      // LOGIN BUTTON
                      // =========================
                      SizedBox(
                        width: double.infinity,
                        height: 56,

                        child: state is AsyncLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: accent),
                              )
                            : ElevatedButton(
                                onPressed: _login,

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,

                                  elevation: 0,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),

                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 22),

                      // =========================
                      // CREATE ACCOUNT
                      // =========================
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.white60),
                          ),

                          TextButton(
                            onPressed: () => context.go('/signup'),

                            child: const Text(
                              "Create account",
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
      ),
    );
  }
}
