// lib/services/upload_service_io.dart
// Android / iOS / Desktop ortamında çalışır
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:foodbridge/core/api_client.dart';
import 'upload_service.dart';

UploadService createUploadServiceImpl() => _IoUploadService();

class _IoUploadService implements UploadService {
  @override
  Future<String> uploadImageFromPath(String filePath, {String? folder}) async {
    try {
      final file = File(filePath);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final res = await apiClient.post(
        '/uploads/image',
        data: formData,
        queryParameters: folder != null ? {'folder': folder} : null,
      );
      final data = res.data;
      if (data is Map) {
        return (data['url'] ?? data['secure_url'] ?? '').toString();
      }
      return data.toString();
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}
