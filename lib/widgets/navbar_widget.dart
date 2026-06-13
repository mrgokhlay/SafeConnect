import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../riverpod/navindex_provider.dart';
import '../riverpod/notification_badges_provider.dart';

class SafeConnectNavBar extends ConsumerWidget {
  const SafeConnectNavBar({super.key});

  final List<String> routes = const [
    '/chat',
    '/requests',
    '/search',
    '/profile',
  ];

  Widget _badge(int count, Color color) {
    return Positioned(
      right: -6,
      top: -6,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          count > 9 ? "9+" : "$count",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData icon, bool selected, ColorScheme colors) {
    return Icon(icon, color: selected ? colors.primary : colors.onSurface);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final currentIndex = ref.watch(navigationIndexProvider);

    // 🔥 CLEAN: direct int values (no .asData handling here anymore)
    final chatUnread = ref.watch(chatUnreadCountProvider).value ?? 0;
    final requestCount = ref.watch(requestBadgeProvider).value ?? 0;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: theme.scaffoldBackgroundColor,
        indicatorColor: colors.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(color: colors.onSurface);
        }),
      ),

      child: NavigationBar(
        height: 70,
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          GoRouter.of(context).go(routes[index]);
        },

        destinations: [
          // ================= CHAT =================
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                _icon(Icons.chat_outlined, false, colors),
                if (chatUnread > 0) _badge(chatUnread, colors.primary),
              ],
            ),
            selectedIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                _icon(Icons.chat_bubble, true, colors),
                if (chatUnread > 0) _badge(chatUnread, colors.primary),
              ],
            ),
            label: 'Chat',
          ),

          // ================= REQUESTS =================
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                _icon(Icons.person_add_alt, false, colors),
                if (requestCount > 0) _badge(requestCount, colors.primary),
              ],
            ),
            selectedIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                _icon(Icons.person_add_alt_1, true, colors),
                if (requestCount > 0) _badge(requestCount, colors.primary),
              ],
            ),
            label: 'Requests',
          ),

          // ================= SEARCH =================
          NavigationDestination(
            icon: _icon(Icons.search_outlined, false, colors),
            selectedIcon: _icon(Icons.search, true, colors),
            label: 'Search',
          ),

          // ================= PROFILE =================
          NavigationDestination(
            icon: _icon(Icons.person_outline, false, colors),
            selectedIcon: _icon(Icons.person, true, colors),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
