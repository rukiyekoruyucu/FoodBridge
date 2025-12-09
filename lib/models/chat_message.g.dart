// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  messageId: json['message_id'] as String,
  donationId: json['donation_id'] as String,
  senderUserId: json['sender_user_id'] as String,
  content: json['content'] as String,
  sentAt: json['sent_at'] as String,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'donation_id': instance.donationId,
      'sender_user_id': instance.senderUserId,
      'content': instance.content,
      'sent_at': instance.sentAt,
    };
