import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../riverpod/logic/request_logic.dart';

final incomingRequestsProvider = StreamProvider.autoDispose<QuerySnapshot>((
  ref,
) {
  final service = ref.watch(requestsServiceProvider);
  return service.incomingRequests();
});

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('MMM d • hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          "Requests",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: requestsAsync.when(
        data: (snapshot) {
          final requests = snapshot.docs;

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_disabled_rounded,
                    size: 70,
                    color: colors.onSurface.withOpacity(.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No connection requests",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "When someone sends you a request, it will appear here",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,

            itemBuilder: (context, index) {
              final request = requests[index];

              final requestId = request.id;
              final senderId = request['senderId'];
              final createdAt = request['createdAt'] as Timestamp?;

              return FutureBuilder(
                future: ref
                    .read(requestsServiceProvider)
                    .getSenderInfo(senderId),

                builder: (context, senderSnapshot) {
                  if (!senderSnapshot.hasData) {
                    return const SizedBox(
                      height: 70,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final sender = senderSnapshot.data!;
                  final username = sender['username'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(.4),
                      ),
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= AVATAR =================
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colors.primary.withOpacity(.15),
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : "U",
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ================= USER INFO =================
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                "wants to connect",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: colors.onSurface.withOpacity(.55),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ================= ACTIONS =================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // BUTTONS SIDE BY SIDE
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 30,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await ref
                                          .read(requestsServiceProvider)
                                          .rejectRequest(requestId);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      minimumSize: Size.zero,
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    child: const Text("Reject"),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                SizedBox(
                                  height: 30,
                                  child: FilledButton(
                                    onPressed: () async {
                                      final chatId = await ref
                                          .read(requestsServiceProvider)
                                          .acceptRequest(requestId, senderId);

                                      if (context.mounted) {
                                        context.push(
                                          '/message',
                                          extra: {
                                            'chatId': chatId,
                                            'otherUserId': senderId,
                                            'otherUsername': username,
                                          },
                                        );
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text("Accept"),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // TIME UNDER BUTTONS
                            Text(
                              _formatTime(createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                // ignore: deprecated_member_use
                                color: colors.onSurface.withOpacity(.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },

        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),

        error: (e, st) => Center(
          child: Text("Error: $e", style: TextStyle(color: colors.error)),
        ),
      ),
    );
  }
}
