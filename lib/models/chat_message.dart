import 'package:json_annotation/json_annotation.dart';

part'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  @JsonKey(name: 'message_id')
  final String messageId;

  @JsonKey(name: 'donation_id')
  final String donationId;

  @JsonKey(name: 'sender_user_id')
  final String senderUserId;

  final String content;

  @JsonKey(name: 'sent_at')
  final String sentAt;

  ChatMessage({
    required this.messageId,
    required this.donationId,
    required this.senderUserId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}