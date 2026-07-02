// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: (json['id'] as num).toInt(),
  roomId: (json['room_id'] as num).toInt(),
  senderId: (json['sender_id'] as num).toInt(),
  content: ChatMessage._readContent(json, 'message') as String? ?? '',
  createdAt: json['created_at'] as String,
  senderFullName: json['full_name'] as String?,
  senderAvatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'room_id': instance.roomId,
      'sender_id': instance.senderId,
      'message': instance.content,
      'created_at': instance.createdAt,
      'full_name': instance.senderFullName,
      'avatar_url': instance.senderAvatarUrl,
    };
