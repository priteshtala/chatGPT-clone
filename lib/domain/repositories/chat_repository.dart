import 'package:chatgpt_clone_pritesh/data/models/conversation.dart';

abstract class ChatRepository {
  Future<List<Conversation>> loadConversations();
  Future<void> saveConversation(Conversation conversation);
  Future<void> deleteConversation(String conversationId);
}
