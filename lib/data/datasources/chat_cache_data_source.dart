import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';

class ChatCacheDataSource {
  ChatCacheDataSource(this._preferences);

  String get _cacheKey {
    // Import Supabase dynamically to get the current user ID for the cache key
    // This isolates local chat storage between different accounts on the same phone.
    try {
      final supabase = Supabase.instance;
      final userId = supabase.client.auth.currentUser?.id;
      if (userId != null) return 'cached_conversations_$userId';
    } catch (_) {}
    return 'cached_conversations';
  }

  final SharedPreferences _preferences;

  Future<List<Conversation>> loadConversations() async {
    final raw = _preferences.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final encoded = jsonEncode(
      conversations.map((conversation) => conversation.toJson()).toList(),
    );
    await _preferences.setString(_cacheKey, encoded);
  }
}
