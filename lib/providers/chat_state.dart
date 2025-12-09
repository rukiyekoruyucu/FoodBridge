import 'package:foodbridge/models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isConnected;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnected,
    String? error,
  }){
    return ChatState(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      error: error,
    );
  }
}