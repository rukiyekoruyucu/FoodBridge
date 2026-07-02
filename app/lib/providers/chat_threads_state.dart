import 'package:foodbridge/models/chat_thread.dart';

class ChatThreadsState {
  final bool isLoading;
  final String? error;
  final List<ChatThread> threads;

  const ChatThreadsState({
    required this.isLoading,
    required this.error,
    required this.threads,
  });

  factory ChatThreadsState.initial() =>
      const ChatThreadsState(isLoading: false, error: null, threads: []);

  ChatThreadsState copyWith({
    bool? isLoading,
    String? error,
    List<ChatThread>? threads,
  }) {
    return ChatThreadsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      threads: threads ?? this.threads,
    );
  }
}