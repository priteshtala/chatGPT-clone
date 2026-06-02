part of 'chat_cubit.dart';

enum ChatStatus { initial, loading, ready, streaming, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.conversations = const [],
    this.activeConversation,
    this.errorMessage,
    this.selectedModel = AppConfig.defaultTextModel,
  });

  final ChatStatus status;
  final List<Conversation> conversations;
  final Conversation? activeConversation;
  final String? errorMessage;
  final String selectedModel;

  List<ChatMessage> get messages => activeConversation?.messages ?? const [];

  ChatState copyWith({
    ChatStatus? status,
    List<Conversation>? conversations,
    Conversation? activeConversation,
    String? errorMessage,
    String? selectedModel,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      activeConversation: activeConversation ?? this.activeConversation,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }

  @override
  List<Object?> get props => [status, conversations, activeConversation, errorMessage, selectedModel];
}
