import 'package:dio/dio.dart';
import 'package:foodbridge/core/api_client.dart';
import 'package:foodbridge/models/chat_message.dart';
import 'package:foodbridge/models/chat_thread.dart';

class ChatApiService {
  final Dio _dio = apiClient;

  Future<ChatThread> openDm(int otherUserId) async {
    // ✅ backend route param + body karma kullanıyor olabilir
    final res = await _dio.post(
      '/chat/dm/$otherUserId',
      data: {'otherUserId': otherUserId},
    );

    final data = Map<String, dynamic>.from(res.data);

    // thread formatı varsa direkt parse
    if (data.containsKey('room_type') || data.containsKey('other_user_id')) {
      return ChatThread.fromJson(data);
    }

    // raw room formatı fallback
    return ChatThread.fromJson({
      'id': data['id'],
      'room_type': data['room_type'] ?? 'DM',
      'other_user_id': otherUserId,
      'other_user_full_name': data['other_user_full_name'],
      'other_user_avatar_url': data['other_user_avatar_url'],
      // ✅ senin model ne bekliyorsa: other_user_avatar_url kullandın
      'last_message': null,
      'last_message_at': null,
    });
  }

  Future<List<ChatThread>> listRooms() async {
    final res = await _dio.get('/chat/rooms');
    final list = (res.data as List).cast<dynamic>();
    return list
        .map((e) => ChatThread.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(int roomId) async {
    final res = await _dio.get('/chat/rooms/$roomId/messages');
    final list = (res.data as List).cast<dynamic>();
    return list
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ChatMessage> sendMessage(int roomId, String message) async {
    final msg = message.trim();
    final res = await _dio.post(
      '/chat/rooms/$roomId/messages',
      data: {
        // ✅ controller text bekliyor, bazı repo message kullanıyor olabilir
        "text": msg,
        "message": msg,
      },
    );
    return ChatMessage.fromJson(Map<String, dynamic>.from(res.data));
  }
}
