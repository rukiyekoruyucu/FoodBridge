// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:foodbridge/core/api_constants.dart';
import 'package:foodbridge/services/auth_service.dart';

final Dio apiClient =
    Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 25),
          sendTimeout: const Duration(seconds: 25),
          headers: {'Accept': 'application/json'},
        ),
      )
      ..interceptors.addAll([
        _AuthInterceptorLite(),
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      ]);

class _AuthInterceptorLite extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await AuthService.instance.getIdToken(forceRefresh: false);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != 401) return handler.next(err);

    final ro = err.requestOptions;

    // aynı istek ikinci kez 401 alıyorsa: logout
    if (ro.extra['retried'] == true) {
      await AuthService.instance.logout();
      return handler.reject(err);
    }

    try {
      await AuthService.instance.getIdToken(forceRefresh: true);
      final token = await AuthService.instance.getIdToken(forceRefresh: false);

      ro.extra['retried'] = true;

      final res = await apiClient.request(
        ro.path,
        data: ro.data,
        queryParameters: ro.queryParameters,
        options: Options(
          method: ro.method,
          headers: {
            ...ro.headers,
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          responseType: ro.responseType,
          contentType: ro.contentType,
          validateStatus: ro.validateStatus,
          receiveDataWhenStatusError: ro.receiveDataWhenStatusError,
          followRedirects: ro.followRedirects,
        ),
        cancelToken: ro.cancelToken,
        onReceiveProgress: ro.onReceiveProgress,
        onSendProgress: ro.onSendProgress,
      );

      handler.resolve(res);
    } catch (e) {
      await AuthService.instance.logout();
      handler.reject(
        e is DioException
            ? e
            : DioException(
                requestOptions: ro,
                error: e,
                type: DioExceptionType.unknown,
              ),
      );
    }
  }
}
