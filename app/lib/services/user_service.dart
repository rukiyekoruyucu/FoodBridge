import 'package:dio/dio.dart';
import 'package:foodbridge/core/api_client.dart';
import 'package:foodbridge/models/user.dart';

class UserService {
  final Dio _dio = apiClient;

  Future<List<dynamic>> getLeaderboard({int limit = 10}) async {
    final res = await _dio.get(
      '/users/leaderboard',
      queryParameters: {'limit': limit},
    );
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return (data['data'] as List);
    return const [];
  }

  Future<Map<String, dynamic>> getMySummary() async {
    final res = await _dio.get('/users/me/summary');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<User> updateMe({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final res = await _dio.patch(
        '/users/me',
        data: {
          if (fullName != null) 'fullName': fullName,
          if (username != null) 'username': username,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (bio != null) 'bio': bio,
        },
      );
      return User.fromJson(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Bu kullanıcı adı zaten alınmış.');
      }
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'];
        if (msg != null) throw Exception(msg.toString());
      }
      if (data is String && data.isNotEmpty) throw Exception(data);
      throw Exception(e.message ?? 'İstek başarısız.');
    }
  }
}
