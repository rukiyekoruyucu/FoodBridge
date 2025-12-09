import 'package:dio/dio.dart';
import 'package:foodbridge/services/auth_service.dart';
import 'dart:developer';

final Dio apiClient = _createDioClient();

Dio _createDioClient() {
  final dio = Dio(BaseOptions(
  baseUrl:'http://localhost:3000/api', 
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 10)
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await AuthService().getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options); 
    },

    onError: (DioException e, handler) {
      log('Dio hata: Url: ${e.requestOptions.uri}, Kod: ${e.response?.statusCode}, Yanıt: ${e.response?.data}', name: 'ApiClientError');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        AuthService().signOut();
        // Handle unauthorized error, e.g., redirect to login
      }
      return handler.next(e);

    }
  ));
  return dio;
}