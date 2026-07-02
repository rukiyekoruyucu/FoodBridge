// lib/core/api_constants.dart
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Production URL - Railway deploy sonrası güncellenecek
  static const String _productionUrl =
      'https://foodbridge-production-7403.up.railway.app';
  static const String _localUrl = 'http://192.168.1.166:3000';

  static String get baseUrl {
    if (kReleaseMode) return '$_productionUrl/api';
    // Debug modda override environment variable varsa kullan
    const override = String.fromEnvironment('API_HOST');
    if (override.isNotEmpty) return 'http://$override:3000/api';
    return '$_localUrl/api';
  }

  static String get socketBaseUrl {
    if (kReleaseMode) return _productionUrl;
    const override = String.fromEnvironment('API_HOST');
    if (override.isNotEmpty) return 'http://$override:3000';
    return _localUrl;
  }
}
