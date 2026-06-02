import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

enum ChatRole { user, assistant, system }

enum ChatMessageType { text, image, audio }

@JsonSerializable()
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.type = ChatMessageType.text,
    this.metadata = const {},
  });

  final String id;
  final String conversationId;
  final ChatRole role;
  final ChatMessageType type;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    ChatRole? role,
    ChatMessageType? type,
    String? content,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  @override
  List<Object?> get props => [
    id,
    conversationId,
    role,
    type,
    content,
    createdAt,
    metadata,
  ];
}
