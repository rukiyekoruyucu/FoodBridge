import 'package:json_annotation/json_annotation.dart';

part 'chat_thread.g.dart';

@JsonSerializable()
class ChatThread {
  final int id;

  @JsonKey(name: 'room_type')
  final String roomType; // DM | DONATION

  @JsonKey(name: 'donation_id')
  final int? donationId;

  @JsonKey(name: 'other_user_id')
  final int? otherUserId;

  @JsonKey(name: 'other_user_full_name')
  final String? otherUserFullName;

  /// backend: other_user_avatar_url OR other_avatar_url
  @JsonKey(name: 'other_avatar_url', readValue: _readAvatar, defaultValue: '')
  final String? otherAvatarUrl;

  @JsonKey(name: 'last_message')
  final String? lastMessage;

  @JsonKey(name: 'last_message_at')
  final String? lastMessageAt;

  ChatThread({
    required this.id,
    required this.roomType,
    this.donationId,
    this.otherUserId,
    this.otherUserFullName,
    this.otherAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
  });

  static Object? _readAvatar(Map<dynamic, dynamic> json, String key) {
    final v = json['other_avatar_url'] ?? json['other_user_avatar_url'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) =>
      _$ChatThreadFromJson(json);

  Map<String, dynamic> toJson() => _$ChatThreadToJson(this);
}
