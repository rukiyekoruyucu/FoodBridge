import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/services/chat_api_service.dart';
import 'chat_threads_state.dart';

final chatThreadsApiProvider = Provider((ref) => ChatApiService());

final chatThreadsProvider =
    StateNotifierProvider.autoDispose<ChatThreadsNotifier, ChatThreadsState>((
      ref,
    ) {
      final api = ref.watch(chatThreadsApiProvider);
      return ChatThreadsNotifier(api)..load();
    });

class ChatThreadsNotifier extends StateNotifier<ChatThreadsState> {
  final ChatApiService _api;

  ChatThreadsNotifier(this._api) : super(ChatThreadsState.initial());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await _api.listRooms();
      state = state.copyWith(isLoading: false, threads: rooms, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}
