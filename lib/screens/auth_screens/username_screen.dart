import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../riverpod/features/username_controller.dart';

class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _usernameController = TextEditingController();

  // =========================
  // COLORS
  // =========================
  static const bg = Color(0xFF070B14); // midnight black
  static const card = Color(0xFF111827); // dark navy
  static const accent = Color(0xFF8B5CF6); // soft violet

  // =========================
  // SAVE USERNAME
  // =========================
  void _saveUsername() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Username cannot be empty"),
        ),
      );
      return;
    }

    // Professional validation
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9._]{2,19}$');
    final consecutive = RegExp(r'([_.])\1');

    if (!regex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "Username must start with a letter and be 3-20 characters",
          ),
        ),
      );
      return;
    }

    if (consecutive.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "Username cannot contain consecutive dots or underscores",
          ),
        ),
      );
      return;
    }

    if (username.endsWith('.') || username.endsWith('_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Username cannot end with dot or underscore"),
        ),
      );
      return;
    }
    try {
      await ref
          .read(usernameControllerProvider.notifier)
          .saveUsername(username);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF8B5CF6),
          duration: Duration(seconds: 2),
          content: Text(
            "Username saved successfully",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      context.go('/chat');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
          content: Text(
            "Error: $e",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  // =========================
  // INPUT DESIGN
  // =========================
  InputDecoration _input() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1A2333),

      hintText: "Choose a username",
      hintStyle: const TextStyle(color: Colors.white38),

      prefixIcon: const Icon(Icons.alternate_email_rounded, color: accent),

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
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usernameControllerProvider);
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
                      color: accent.withOpacity(0.14),
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
                      width: 90,
                      height: 90,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // ignore: deprecated_member_use
                        color: accent.withOpacity(0.12),

                        // ignore: deprecated_member_use
                        border: Border.all(color: accent.withOpacity(0.3)),
                      ),

                      child: const Icon(
                        Icons.person_rounded,
                        color: accent,
                        size: 42,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =========================
                    // TITLE
                    // =========================
                    const Text(
                      "Create Username",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "This username will be visible to other users on SafeConnect.",
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // =========================
                    // USERNAME FIELD
                    // =========================
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),

                      decoration: _input(),
                    ),

                    const SizedBox(height: 18),

                    // =========================
                    // USERNAME RULES
                    // =========================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2333),
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Username Rules",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 8),

                          Text(
                            "• Must start with a letter\n"
                            "• 3 to 20 characters only\n"
                            "• Letters, numbers, dots and underscores allowed\n"
                            "• No consecutive dots or underscores",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =========================
                    // SAVE BUTTON
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      height: 56,

                      child: state.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: accent),
                            )
                          : ElevatedButton(
                              onPressed: _saveUsername,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),

                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),

                    // =========================
                    // ERROR
                    // =========================
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

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
