import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../data/models/chat_message.dart';
import '../cubit/chat_cubit.dart';
import 'audio_message_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatCubit, ChatState, List<ChatMessage>>(
      selector: (state) => state.messages,
      builder: (context, messages) {
        if (messages.isEmpty) {
          return const _EmptyState();
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          itemCount: messages.length,
          keyboardDismissBehavior: .onDrag,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            return _MessageBubble(message: message);
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 48, color: colorScheme.primary),
              const Gap(16),
              Text('How can I help you today?', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const Gap(12),
              Text(
                'Ask a question, upload a photo, or create speech from text.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    final background = isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
        child: _MessageContent(message: message),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.image:
        if (message.content.startsWith('http')) {
          return Image.network(message.content);
        }
        return Text(message.content);
      case ChatMessageType.audio:
        final audioPath = message.metadata['audio_path'] as String?;
        return AudioMessageBubble(audioPath: audioPath, base64Audio: audioPath == null ? message.content : null);
      case ChatMessageType.text:
        final imageBase64 = message.metadata['image_base64'] as String?;
        final isEmpty = message.content.isEmpty;

        if (imageBase64 != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(imageBase64), height: 200, fit: BoxFit.cover),
              ),
              if (!isEmpty) const Gap(8),
              if (!isEmpty) SelectableText(message.content),
            ],
          );
        }

        if (isEmpty) {
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              Gap(12),
              Text('Typing...'),
            ],
          );
        }

        return SelectableText(message.content);
    }
  }
}
