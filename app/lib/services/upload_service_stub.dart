// lib/services/upload_service_stub.dart
// Fallback stub — ne web ne io ortamında kullanılır
import 'upload_service.dart';

UploadService createUploadServiceImpl() =>
    throw UnsupportedError('Bu platformda upload desteklenmiyor.');
