import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/presence_service.dart';

class ConnectDialog {
  ConnectDialog._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static void show(
    BuildContext context,
    Future<String> Function(String) createOrGetChat,
  ) {
    final currentUserId = _auth.currentUser!.uid;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Your Connections",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chat_requests')
                      .where('status', isEqualTo: 'accepted')
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    final Set<String> userIds = {};

                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      final sender = data['senderId'];
                      final receiver = data['receiverId'];

                      if (sender == currentUserId) {
                        userIds.add(receiver);
                      } else if (receiver == currentUserId) {
                        userIds.add(sender);
                      }
                    }

                    if (userIds.isEmpty) {
                      return Center(
                        child: Text(
                          "No connections yet",
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: userIds.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),

                      itemBuilder: (context, index) {
                        final uid = userIds.elementAt(index);

                        return StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('users')
                              .doc(uid)
                              .snapshots(),

                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const SizedBox();
                            }

                            final data =
                                snap.data!.data() as Map<String, dynamic>? ??
                                {};

                            final username = data['username'] ?? 'Unknown';

                            // ✅ FIXED: REAL PRESENCE (RTDB)
                            return StreamBuilder<bool>(
                              stream: PresenceService.instance.isOnlineStream(
                                uid,
                              ),

                              builder: (context, onlineSnap) {
                                final isOnline = onlineSnap.data ?? false;

                                return Material(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),

                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),

                                    onTap: () async {
                                      final chatId = await createOrGetChat(uid);

                                      if (!context.mounted) return;

                                      Navigator.pop(context);

                                      if (!context.mounted) return;

                                      context.push(
                                        '/message',
                                        extra: {
                                          'chatId': chatId,
                                          'otherUserId': uid,
                                          'otherUsername': username,
                                        },
                                      );
                                    },

                                    child: ListTile(
                                      leading: Stack(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: colors.primary
                                                .withOpacity(0.2),
                                            child: Text(
                                              username.isNotEmpty
                                                  ? username[0].toUpperCase()
                                                  : 'U',
                                              style: TextStyle(
                                                color: colors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isOnline
                                                    ? Colors.green
                                                    : Colors.grey,
                                                border: Border.all(
                                                  color: theme.cardColor,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      title: Text(
                                        username,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                  ),
                                );
                              },
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
      },
    );
  }
}
