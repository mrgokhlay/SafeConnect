import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: 78,
      elevation: 0,

      // 👇 now fully controlled by ThemeData
      title: Text(
        "SafeConnect",
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: colors.primary,
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () => context.push('/ai'),
            icon: Icon(Icons.auto_awesome, color: colors.primary),
            label: Text(
              "AI",
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
