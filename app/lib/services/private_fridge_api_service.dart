import 'package:foodbridge/core/api_client.dart';
import 'package:foodbridge/models/private_fridge.dart';

class PrivateFridgeApiService {
  Future<List<PrivateFridge>> listMyPrivateFridges() async {
    final res = await apiClient.get('/private-fridges');
    final data = res.data;

    // backend array döndürüyor varsayıyorum
    final List<dynamic> arr = (data is List) ? data : (data['fridges'] as List);
    return arr.map((e) => PrivateFridge.fromJson(e)).toList();
  }

  Future<PrivateFridge> createPrivateFridge({
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'latitude': latitude,
      'longitude': longitude,
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
    };

    final res = await apiClient.post('/private-fridges', data: data);

    final json = (res.data is Map && res.data['fridge'] != null)
        ? res.data['fridge']
        : res.data;

    return PrivateFridge.fromJson(Map<String, dynamic>.from(json));
  }

  Future<PrivateFridge> updatePrivateFridge(
    String id, {
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final res = await apiClient.put(
      '/private-fridges/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      },
    );

    final json = (res.data is Map && res.data['fridge'] != null)
        ? res.data['fridge']
        : res.data;

    return PrivateFridge.fromJson(Map<String, dynamic>.from(json));
  }

  Future<void> deletePrivateFridge(String id) async {
    await apiClient.delete('/private-fridges/$id');
  }

  Future<List<Map<String, dynamic>>> listItemsInPrivateFridge(
    String fridgeId,
  ) async {
    final res = await apiClient.get('/private-fridges/$fridgeId/items');
    final data = res.data;

    final List<dynamic> arr = (data is List)
        ? data
        : (data is Map && data['items'] is List)
        ? (data['items'] as List)
        : const [];

    return arr.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> updatePrivateItem(
    String fridgeId,
    int itemId, {
    String? name,
    String? description,
    String? category,
    int? quantity,
    DateTime? expiryDate,
    String? unit,
    String? imageUrl,
  }) async {
    final res = await apiClient.put(
      '/private-fridges/$fridgeId/items/$itemId',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );

    final data = res.data;
    final json = (data is Map && data['item'] is Map) ? data['item'] : data;
    return Map<String, dynamic>.from(json as Map);
  }

  Future<List<Map<String, dynamic>>> listExpiringItemsInPrivateFridge(
    String fridgeId, {
    int daysBefore = 3,
  }) async {
    final res = await apiClient.get(
      '/private-fridges/$fridgeId/items-expiring',
      queryParameters: {'daysBefore': daysBefore},
    );
    final data = res.data;
    final List<dynamic> arr = (data is Map && data['items'] is List)
        ? (data['items'] as List)
        : const [];
    return arr.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> deletePrivateItem(String fridgeId, int itemId) async {
    await apiClient.delete('/private-fridges/$fridgeId/items/$itemId');
  }

  Future<void> addItemToPrivateFridge(
    String fridgeId, {
    required String name,
    required int quantity,
    String? category,
    String? description,
    DateTime? expiryDate,
    String? unit,
    String? imageUrl,
  }) async {
    await apiClient.post(
      '/private-fridges/$fridgeId/items',
      data: {
        'name': name,
        'quantity': quantity,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
        if (unit != null) 'unit': unit,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
  }
}
