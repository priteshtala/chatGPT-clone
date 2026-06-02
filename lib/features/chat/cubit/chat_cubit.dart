import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/conversation.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/repositories/openai_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({required ChatRepository chatRepository, required OpenAiRepository openAiRepository})
    : _chatRepository = chatRepository,
      _openAiRepository = openAiRepository,
      super(const ChatState());

  final ChatRepository _chatRepository;
  final OpenAiRepository _openAiRepository;
  StreamSubscription<String>? _streamSubscription;

  Future<void> loadConversations() async {
    emit(state.copyWith(status: ChatStatus.loading, clearError: true));
    try {
      final conversations = await _chatRepository.loadConversations();
      emit(
        state.copyWith(
          status: ChatStatus.ready,
          conversations: conversations,
          activeConversation: conversations.isEmpty ? Conversation.empty() : conversations.first,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: ChatStatus.failure, errorMessage: error.toString()));
    }
  }

  void startNewChat() {
    emit(state.copyWith(status: ChatStatus.ready, activeConversation: Conversation.empty(), clearError: true));
  }

  void selectConversation(String conversationId) {
    final conversation = state.conversations.firstWhere((item) => item.id == conversationId, orElse: Conversation.empty);
    emit(state.copyWith(activeConversation: conversation, clearError: true));
  }

  Future<void> sendText(String prompt, {String? imageBase64}) async {
    final trimmed = prompt.trim();
    if ((trimmed.isEmpty && imageBase64 == null) || state.status == ChatStatus.streaming) return;

    final conversation = state.activeConversation ?? Conversation.empty();
    final userMessage = _message(
      conversationId: conversation.id,
      role: ChatRole.user,
      content: trimmed,
    ).copyWith(metadata: imageBase64 != null ? {'image_base64': imageBase64} : {});
    final assistantMessage = _message(conversationId: conversation.id, role: ChatRole.assistant, content: '');

    final title = conversation.title == 'New chat' ? _titleFromPrompt(trimmed) : conversation.title;
    final nextConversation = conversation.copyWith(
      title: title.isEmpty ? 'Image chat' : title,
      updatedAt: DateTime.now(),
      messages: [...conversation.messages, userMessage, assistantMessage],
    );

    _replaceConversation(nextConversation, status: ChatStatus.streaming);

    var accumulated = '';
    await _streamSubscription?.cancel();
    _streamSubscription = _openAiRepository
        .streamTextReply(
          messages: nextConversation.messages.where((m) => m.content.isNotEmpty || m.metadata.containsKey('image_base64')).toList(),
          model: state.selectedModel,
        )
        .listen(
          (chunk) {
            accumulated += chunk;
            _updateLastAssistant(nextConversation.id, accumulated);
          },
          onError: (Object error) {
            final errorString = error.toString().toLowerCase();
            if (errorString.contains('404') || errorString.contains('400') || errorString.contains('not found') || errorString.contains('503')) {
              _updateLastAssistant(
                nextConversation.id,
                'I apologize, but the selected AI model encountered an error or is no longer available. I have automatically switched to the default Llama 4 Scout model. Please tap send to try again.',
              );
              emit(
                state.copyWith(
                  status: ChatStatus.failure,
                  errorMessage: 'Model error, switched to default',
                  selectedModel: 'meta-llama/llama-4-scout-17b-16e-instruct',
                ),
              );
            } else {
              _updateLastAssistant(nextConversation.id, _friendlyError(error));
              emit(state.copyWith(status: ChatStatus.failure, errorMessage: error.toString()));
            }
          },
          onDone: () async {
            final done = state.activeConversation;
            if (done != null) {
              await _chatRepository.saveConversation(done);
            }
            emit(state.copyWith(status: ChatStatus.ready));
          },
        );
  }

  Future<String> transcribeVoiceNote(String audioPath) async {
    try {
      final modelToUseForTranscription = AppConfig.hasGroqKey ? 'whisper-large-v3' : 'whisper-1';
      final transcribedText = await _openAiRepository.transcribeAudio(filePath: audioPath, model: modelToUseForTranscription);
      if (transcribedText.trim().isEmpty) {
        throw Exception('Could not transcribe audio. Please try speaking clearly.');
      }
      return transcribedText;
    } catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  Future<void> textToSpeech(String text) async {
    await _appendToolResult(
      prompt: text,
      type: ChatMessageType.audio,
      loaderText: 'Generating speech...',
      action: () => _openAiRepository.textToSpeech(text: text, model: AppConfig.defaultSpeechModel),
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    await _chatRepository.deleteConversation(conversationId);
    final conversations = state.conversations.where((item) => item.id != conversationId).toList();
    emit(state.copyWith(conversations: conversations, activeConversation: conversations.isEmpty ? Conversation.empty() : conversations.first));
  }

  void setModel(String model) {
    emit(state.copyWith(selectedModel: model));
  }

  Future<void> _appendToolResult({
    required String prompt,
    required ChatMessageType type,
    required String loaderText,
    required Future<String> Function() action,
  }) async {
    final conversation = state.activeConversation ?? Conversation.empty();
    final userMessage = _message(conversationId: conversation.id, role: ChatRole.user, content: prompt);
    final assistantMessage = _message(conversationId: conversation.id, role: ChatRole.assistant, content: loaderText, type: type);
    final pending = conversation.copyWith(
      title: conversation.title == 'New chat' ? _titleFromPrompt(prompt) : conversation.title,
      updatedAt: DateTime.now(),
      messages: [...conversation.messages, userMessage, assistantMessage],
    );
    _replaceConversation(pending, status: ChatStatus.loading);

    try {
      final result = await action();
      _updateLastAssistant(conversation.id, result, type: type);
      final done = state.activeConversation;
      if (done != null) await _chatRepository.saveConversation(done);
      emit(state.copyWith(status: ChatStatus.ready));
    } catch (error) {
      emit(state.copyWith(status: ChatStatus.failure, errorMessage: error.toString()));
    }
  }

  void _updateLastAssistant(String conversationId, String content, {ChatMessageType type = ChatMessageType.text}) {
    final conversation = state.activeConversation;
    if (conversation == null || conversation.id != conversationId) return;
    final messages = [...conversation.messages];
    final index = messages.lastIndexWhere((m) => m.role == ChatRole.assistant);
    if (index == -1) return;

    messages[index] = messages[index].copyWith(content: content, type: type);
    _replaceConversation(
      conversation.copyWith(messages: messages, updatedAt: DateTime.now()),
      status: ChatStatus.streaming,
    );
  }

  void _replaceConversation(Conversation conversation, {ChatStatus? status}) {
    final conversations = [conversation, ...state.conversations.where((item) => item.id != conversation.id)]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    emit(state.copyWith(status: status, conversations: conversations, activeConversation: conversation, clearError: true));
  }

  ChatMessage _message({
    required String conversationId,
    required ChatRole role,
    required String content,
    ChatMessageType type = ChatMessageType.text,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: now.microsecondsSinceEpoch.toString(),
      conversationId: conversationId,
      role: role,
      type: type,
      content: content,
      createdAt: now,
    );
  }

  String _titleFromPrompt(String prompt) {
    final normalized = prompt.replaceAll(RegExp(r'\s+'), ' ');
    return normalized.length <= 36 ? normalized : '${normalized.substring(0, 36)}...';
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('quota')) {
      return 'OpenAI quota is exceeded for this API key. Please add billing or use another active API key, then send the message again.';
    }
    return 'I could not complete this request. $message';
  }

  void stopGeneration() {
    _streamSubscription?.cancel();

    final conversation = state.activeConversation;
    if (conversation != null) {
      final messages = [...conversation.messages];
      final index = messages.lastIndexWhere((m) => m.role == ChatRole.assistant);
      if (index != -1 && messages[index].content.isEmpty) {
        messages[index] = messages[index].copyWith(content: 'Generation cancelled.');
        _replaceConversation(
          conversation.copyWith(messages: messages, updatedAt: DateTime.now()),
          status: ChatStatus.ready,
        );
        _chatRepository.saveConversation(state.activeConversation!);
      } else {
        emit(state.copyWith(status: ChatStatus.ready));
        _chatRepository.saveConversation(conversation);
      }
    } else {
      emit(state.copyWith(status: ChatStatus.ready));
    }
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    return super.close();
  }
}
