import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/app_color.dart';
import '../../riverpod/logic/search_logic.dart';
import '../../riverpod/logic/request_logic.dart';

final searchQueryProvider = StateProvider<String>((ref) => "");

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchService = ref.watch(searchServiceProvider);
    final requestsService = ref.watch(requestsServiceProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ================= APP BAR =================
      appBar: AppBar(title: const Text("Find People"), centerTitle: true),

      body: Column(
        children: [
          // ================= SEARCH BOX =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                style: theme.textTheme.bodyLarge,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value.trim();
                },
                decoration: InputDecoration(
                  hintText: "Search users...",
                  hintStyle: theme.textTheme.bodyMedium,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
          ),

          // ================= RESULTS =================
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: searchService.searchUsers(query),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final users = snapshot.data!;

                if (query.trim().isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 70,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Search users",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Find people by typing their username",
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 70,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No users found",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Try a different username or spelling",
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: users.length,

                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user['uid'];
                    final isMe = user['isMe'] == true;

                    return StreamBuilder<String>(
                      stream: requestsService.relationshipStream(userId),

                      builder: (context, statusSnapshot) {
                        final status = statusSnapshot.data ?? "none";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              // ================= AVATAR =================
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary.withOpacity(
                                  .15,
                                ),

                                backgroundImage: user['profileImage'] != null
                                    ? NetworkImage(user['profileImage'])
                                    : null,

                                child: user['profileImage'] == null
                                    ? Text(
                                        user['username']
                                            .toString()[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),

                              const SizedBox(width: 12),

                              // ================= USER INFO =================
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['username'] ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              // ================= ACTION =================
                              if (!isMe)
                                _buildActionButton(
                                  status,
                                  requestsService,
                                  userId,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButton(
    String status,
    RequestsService requestsService,
    String userId,
  ) {
    switch (status) {
      case "connected":
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.emerald.withOpacity(.15),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            "Connected",
            style: TextStyle(
              color: AppColors.emerald,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case "pending_sent":
        return OutlinedButton.icon(
          onPressed: () => requestsService.cancelRequest(userId),
          icon: const Icon(Icons.close),
          label: const Text("Cancel"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
        );

      case "pending_received":
        return const Text(
          "Requested",
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        );

      default:
        return FilledButton.icon(
          onPressed: () async {
            await requestsService.sendRequest(userId);
          },
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text("Connect"),
        );
    }
  }
}
