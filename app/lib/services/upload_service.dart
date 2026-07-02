// lib/services/upload_service.dart

// ⚠️ IMPORTLAR EN ÜSTTE OLMAK ZORUNDA
import 'upload_service_stub.dart'
    if (dart.library.io) 'upload_service_io.dart'
    if (dart.library.html) 'upload_service_web.dart';

/// Ortak arayüz
abstract class UploadService {
  Future<String> uploadImageFromPath(String filePath, {String? folder});
}

/// Platforma göre doğru implementasyonu döner
UploadService createUploadService() => createUploadServiceImpl();
