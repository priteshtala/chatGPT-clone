import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../data/models/conversation.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/cubit/auth_cubit.dart' as import_auth;
import '../cubit/chat_cubit.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = context.read<AuthRepository>().currentUser?.email ?? 'User';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      userEmail,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('New chat', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  context.read<ChatCubit>().startNewChat();
                },
              ),
            ),
            
            const Gap(16),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recent Chats',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const Gap(8),

            Expanded(
              child: BlocSelector<ChatCubit, ChatState, List<Conversation>>(
                selector: (state) => state.conversations,
                builder: (context, conversations) {
                  if (conversations.isEmpty) {
                    return Center(
                      child: Text(
                        'No chats yet',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: conversations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return ListTile(
                        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                        contentPadding: const EdgeInsets.only(left: 16, right: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: const Icon(Icons.chat_bubble_outline, size: 20),
                        title: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => context.read<ChatCubit>().deleteConversation(conversation.id),
                        ),
                        onTap: () {
                          context.read<ChatCubit>().selectConversation(conversation.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            
            const Divider(height: 1),
            
            // Sign Out Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: () {
                  Navigator.pop(context);
                  context.read<import_auth.AuthCubit>().signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
