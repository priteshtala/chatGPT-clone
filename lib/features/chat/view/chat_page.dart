import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/settings/cubit/settings_cubit.dart';
import '../cubit/chat_cubit.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/message_list.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: BlocSelector<ChatCubit, ChatState, String>(
          selector: (state) => state.activeConversation?.title ?? 'New chat',
          builder: (context, title) {
            return Text(title, maxLines: 1, overflow: TextOverflow.ellipsis);
          },
        ),
        actions: [
          IconButton(tooltip: 'New chat', icon: const Icon(Icons.add_comment_outlined), onPressed: context.read<ChatCubit>().startNewChat),
          BlocSelector<SettingsCubit, SettingsState, ThemeMode>(
            selector: (state) => state.themeMode,
            builder: (context, themeMode) {
              return PopupMenuButton<ThemeMode>(
                tooltip: 'Theme',
                icon: const Icon(Icons.contrast_outlined),
                initialValue: themeMode,
                onSelected: context.read<SettingsCubit>().setThemeMode,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: ThemeMode.system, child: Text('System')),
                  PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
                  PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Expanded(child: MessageList()),
          BlocSelector<ChatCubit, ChatState, String?>(
            selector: (state) => state.activeConversation?.id,
            builder: (context, activeId) {
              return ChatComposer(key: ValueKey(activeId));
            },
          ),
        ],
      ),
    );
  }
}
