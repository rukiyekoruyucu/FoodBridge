import 'package:json_annotation/json_annotation.dart';
part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  final int id;

  @JsonKey(name: 'room_id')
  final int roomId;

  @JsonKey(name: 'sender_id')
  final int senderId;

  /// backend: text OR message
  @JsonKey(name: 'message', readValue: _readContent, defaultValue: '')
  final String content;

  @JsonKey(name: 'created_at')
  final String createdAt;

  // opsiyonel (listMessages JOIN users döndürüyorsa)
  @JsonKey(name: 'full_name')
  final String? senderFullName;

  @JsonKey(name: 'avatar_url')
  final String? senderAvatarUrl;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderFullName,
    this.senderAvatarUrl,
  });

  static Object? _readContent(Map<dynamic, dynamic> json, String key) {
    final v = json['message'] ?? json['text'] ?? json['content'];
    return (v ?? '').toString();
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
