import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';

class SupabaseChatDataSource {
  SupabaseChatDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Conversation>> loadConversations() async {
    final rows = await _client
        .from('conversations')
        .select('payload')
        .order('updated_at', ascending: false);

    return rows
        .map<Conversation>(
          (row) =>
              Conversation.fromJson(row['payload'] as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> upsertConversation(Conversation conversation) async {
    await _client.from('conversations').upsert({
      'id': conversation.id,
      'title': conversation.title,
      'updated_at': conversation.updatedAt.toIso8601String(),
      'payload': conversation.toJson(),
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    await _client.from('conversations').delete().eq('id', conversationId);
  }
}
