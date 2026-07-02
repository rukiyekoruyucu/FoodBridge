import 'package:foodbridge/models/chat_message.dart';

class ChatState {
  final bool isLoading;
  final String? error;
  final List<ChatMessage> messages;

  const ChatState({
    required this.isLoading,
    required this.error,
    required this.messages,
  });

  factory ChatState.initial() =>
      const ChatState(isLoading: false, error: null, messages: []);

  ChatState copyWith({
    bool? isLoading,
    String? error,
    List<ChatMessage>? messages,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      messages: messages ?? this.messages,
    );
  }
}
