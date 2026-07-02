import 'package:dio/dio.dart';
import 'package:foodbridge/core/api_client.dart';
import 'package:foodbridge/models/user.dart';

class AuthApiService {
  final Dio _dio = apiClient;

  Future<User> register({
    required String firebaseUid,
    required String fullName,
    required String email,
    required String username,
    required String role,
    String? companyName,
    String? location,
  }) async {
    final payload = <String, dynamic>{
      "firebaseUid": firebaseUid,
      "fullName": fullName,
      "username": username,
      "email": email,
      "role": role,
      if (companyName != null) "companyName": companyName,
      if (location != null) "location": location,
    };

    final res = await _dio.post("/auth/register", data: payload);
    return User.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// Token interceptor’dan otomatik eklenecek
  Future<User> meWithToken(String idToken) async {
    final res = await _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
    return User.fromJson(Map<String, dynamic>.from(res.data));
  }
}
