import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_cache_data_source.dart';
import '../datasources/supabase_chat_data_source.dart';
import '../models/conversation.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatCacheDataSource cacheDataSource, SupabaseChatDataSource? supabaseDataSource})
    : _cacheDataSource = cacheDataSource,
      _supabaseDataSource = supabaseDataSource;

  final ChatCacheDataSource _cacheDataSource;
  final SupabaseChatDataSource? _supabaseDataSource;

  @override
  Future<List<Conversation>> loadConversations() async {
    final cached = await _cacheDataSource.loadConversations();

    try {
      final remote = await _supabaseDataSource?.loadConversations();
      if (remote != null) {
        await _cacheDataSource.saveConversations(remote);
        return remote;
      }
    } catch (_) {
      return cached;
    }

    return cached;
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final conversations = await _cacheDataSource.loadConversations();
    final next = [conversation, ...conversations.where((item) => item.id != conversation.id)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    await _cacheDataSource.saveConversations(next);
    try {
      await _supabaseDataSource?.upsertConversation(conversation);
    } catch (_) {
      // Local cache is the offline source of truth; remote sync can retry later.
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final conversations = await _cacheDataSource.loadConversations();
    await _cacheDataSource.saveConversations(conversations.where((item) => item.id != conversationId).toList());
    try {
      await _supabaseDataSource?.deleteConversation(conversationId);
    } catch (_) {
      // Keep the UI responsive even when Supabase is not configured yet.
    }
  }
}
