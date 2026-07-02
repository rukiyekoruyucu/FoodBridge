import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/models/chat_message.dart';
import 'package:foodbridge/services/chat_api_service.dart';
import 'package:foodbridge/services/chat_service.dart';
import 'chat_state.dart';

final chatApiProvider = Provider((ref) => ChatApiService());
final chatServiceProvider = Provider((ref) => ChatService());

final chatProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, int>((ref, roomId) {
      final api = ref.watch(chatApiProvider);
      final svc = ref.watch(chatServiceProvider);

      final notifier = ChatNotifier(roomId, api, svc);

      notifier.loadHistory();
      notifier.initSocket();

      ref.onDispose(() {
        svc.dispose();
      });

      return notifier;
    });

class ChatNotifier extends StateNotifier<ChatState> {
  final int _roomId;
  final ChatApiService _api;
  final ChatService _svc;

  ChatNotifier(this._roomId, this._api, this._svc) : super(ChatState.initial());

  DateTime _safeParse(String s) {
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final msgs = await _api.getMessages(_roomId);

      // ✅ Sıralama fix: backend DESC dönse bile UI düzgün olsun
      final sorted = [...msgs]
        ..sort(
          (a, b) => _safeParse(a.createdAt).compareTo(_safeParse(b.createdAt)),
        );

      state = state.copyWith(isLoading: false, messages: sorted, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> initSocket() async {
    try {
      await _svc.connectAndAuthenticate();
      _svc.joinChatRoom(_roomId);

      _svc.onNewMessage((data) {
        final msg = ChatMessage.fromJson(data);
        if (msg.roomId == _roomId) {
          addIncoming(msg);
        }
      });
    } catch (_) {
      // socket fail olursa REST yine çalışır
    }
  }

  Future<void> sendMessage(String content, {int? myUserId}) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final optimistic = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      roomId: _roomId,
      senderId: myUserId ?? -1,
      content: text,
      createdAt: DateTime.now().toIso8601String(),
    );

    state = state.copyWith(messages: [...state.messages, optimistic]);

    try {
      final created = await _api.sendMessage(_roomId, text);

      final updated = [...state.messages];
      final idx = updated.indexWhere((m) => m.id == optimistic.id);
      if (idx != -1) {
        updated[idx] = created;
      } else {
        updated.add(created);
      }

      // küçük garanti: order bozulmasın
      updated.sort(
        (a, b) => _safeParse(a.createdAt).compareTo(_safeParse(b.createdAt)),
      );

      state = state.copyWith(messages: updated);
    } catch (e) {
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != optimistic.id).toList(),
        error: e.toString(),
      );
    }
  }

  void addIncoming(ChatMessage msg) {
    final exists = state.messages.any((m) => m.id == msg.id);
    if (exists) return;

    final updated = [...state.messages, msg]
      ..sort(
        (a, b) => _safeParse(a.createdAt).compareTo(_safeParse(b.createdAt)),
      );

    state = state.copyWith(messages: updated);
  }

  void clearError() => state = state.copyWith(error: null);
}
