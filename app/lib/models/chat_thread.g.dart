// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatThread _$ChatThreadFromJson(Map<String, dynamic> json) => ChatThread(
  id: (json['id'] as num).toInt(),
  roomType: json['room_type'] as String,
  donationId: (json['donation_id'] as num?)?.toInt(),
  otherUserId: (json['other_user_id'] as num?)?.toInt(),
  otherUserFullName: json['other_user_full_name'] as String?,
  otherAvatarUrl:
      ChatThread._readAvatar(json, 'other_avatar_url') as String? ?? '',
  lastMessage: json['last_message'] as String?,
  lastMessageAt: json['last_message_at'] as String?,
);

Map<String, dynamic> _$ChatThreadToJson(ChatThread instance) =>
    <String, dynamic>{
      'id': instance.id,
      'room_type': instance.roomType,
      'donation_id': instance.donationId,
      'other_user_id': instance.otherUserId,
      'other_user_full_name': instance.otherUserFullName,
      'other_avatar_url': instance.otherAvatarUrl,
      'last_message': instance.lastMessage,
      'last_message_at': instance.lastMessageAt,
    };
