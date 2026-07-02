import 'package:dio/dio.dart';
import 'package:foodbridge/core/api_client.dart';
import 'package:flutter/foundation.dart';

class ItemService {
  // ✅ backend bazen {data:[...]} gibi Map döndürebiliyor -> bunu normalize ediyoruz
  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final v = data['data'] ?? data['items'] ?? data['results'];
      if (v is List) return v;
    }
    return const [];
  }

  Future<List<dynamic>> getLatestFeed({
    String? category,
    String? q,
    int limit = 20,
  }) async {
    try {
      final res = await apiClient.get(
        '/items/feed',
        queryParameters: {
          'mode': 'latest',
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          'limit': limit,
        },
      );
      return _asList(res.data).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<Map<String, dynamic>> getItemDetail({required int id}) async {
    try {
      final res = await apiClient.get('/items/$id');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<List<dynamic>> getMapMarkers({
    required double lat,
    required double lng,
    double radiusKm = 10,
    String? category,
    String? q,
    int limit = 200,
  }) async {
    try {
      final qp = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'limit': limit,
      };
      if (category != null && category.trim().isNotEmpty) {
        qp['category'] = category.trim();
      }
      if (q != null && q.trim().isNotEmpty) qp['q'] = q.trim();

      final res = await apiClient.get('/items/map', queryParameters: qp);
      return _asList(res.data).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<List<dynamic>> getNearbyFeed({
    required double lat,
    required double lng,
    double radiusKm = 10,
    String? category,
    String? q,
    int limit = 20,
  }) async {
    try {
      final res = await apiClient.get(
        '/items/feed',
        queryParameters: {
          'mode': 'nearby',
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          'limit': limit,
        },
      );
      return _asList(res.data).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<void> createPublicItem({
    required String name,
    String? description,
    String? category,
    int? quantity,
    String? imageUrl,
    required DateTime expiryDate,
    required double lat,
    required double lng,
    String? address,
  }) async {
    try {
      final img = (imageUrl ?? '').trim();

      await apiClient.post(
        '/items',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (category != null) 'category': category,
          if (quantity != null) 'quantity': quantity,
          if (img.isNotEmpty) 'imageUrl': img, // ✅
          'expiryDate': expiryDate.toIso8601String(),
          'lat': lat,
          'lng': lng,
          if (address != null && address.trim().isNotEmpty)
            'address': address.trim(),
        },
      );
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<List<dynamic>> getMyPublicItems({int limit = 200}) async {
    try {
      final res = await apiClient.get(
        '/items/my-public',
        queryParameters: {
          'limit': limit,
          '_ts': DateTime.now().millisecondsSinceEpoch, // ✅ cache bust
        },
        options: Options(
          headers: const {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );
      return _asList(res.data).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<Map<String, dynamic>> updateMyItem({
    required int id,
    String? name,
    String? description,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    String? address,
    String? imageUrl, // ✅ ekle
  }) async {
    try {
      final img = (imageUrl ?? '').trim();

      final res = await apiClient.put(
        '/items/$id',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description, // ✅
          if (category != null) 'category': category, // ✅
          if (quantity != null) 'quantity': quantity,
          if (unit != null) 'unit': unit, // ✅
          if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
          if (address != null) 'address': address, // ✅
          if (img.isNotEmpty) 'imageUrl': img, // ✅
        },
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<Map<String, dynamic>> removeMyItem({required int id}) async {
    try {
      final res = await apiClient.delete('/items/$id');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<List<dynamic>> getPublicItemsByUser({
    required int userId,
    int limit = 30,
  }) async {
    try {
      final res = await apiClient.get(
        '/items/by-user/$userId',
        queryParameters: {'limit': limit},
      );
      return _asList(res.data).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  /// ✅ Public profile bundle:
  /// - /users/:id/public varsa header dolsun
  /// - yoksa bile items gelsin
  Future<Map<String, dynamic>> getPublicProfileBundle({
    required int userId,
    int limit = 30,
  }) async {
    try {
      Map<String, dynamic> userMap = {'id': userId};

      // user (opsiyonel endpoint) — ama artık sessiz geçmiyoruz
      try {
        final path = '/users/$userId/public';
        final uRes = await apiClient.get(path);

        final data = uRes.data;

        // Bazı backendler {user, items} döner, bazıları {data:{...}} döner.
        Map<String, dynamic>? root;
        if (data is Map) root = Map<String, dynamic>.from(data);

        // data wrapper varsa aç
        final wrapped = (root?['data'] is Map)
            ? Map<String, dynamic>.from(root!['data'])
            : null;
        final base = wrapped ?? root ?? <String, dynamic>{};

        final maybeUser = base['user'];
        if (maybeUser is Map) {
          userMap = Map<String, dynamic>.from(maybeUser);
        } else {
          // bazı implementasyonlar user objesini direkt döndürüyor olabilir
          userMap = Map<String, dynamic>.from(base);
        }

        debugPrint('Public user fetched: keys=${userMap.keys}');
      } catch (e) {
        debugPrint(
          'getPublicProfileBundle user fetch failed for id=$userId: $e',
        );
        // userMap id ile kalır, ama en azından sebebi görürsün
      }

      final items = await getPublicItemsByUser(userId: userId, limit: limit);
      return {'user': userMap, 'items': items};
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<List<dynamic>> getMyPrivateItems({int limit = 200}) async {
    try {
      final res = await apiClient.get(
        '/items/my',
        queryParameters: {'limit': limit},
      );
      return _asList(res.data).toList();
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'] ?? data['message'];
      if (err is String && err.isNotEmpty) return err;
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'İstek başarısız.';
  }
}
