import 'package:foodbridge/core/api_client.dart';
import 'package:foodbridge/models/product_item.dart';

/// ✅ Tüm endpoint'ler düzeltildi:
///   - /private-fridge (tekil) → /private-fridges (çoğul)
///   - POST /items/my → private-fridges API'sine yönlendirildi
///   - transfer → doğru endpoint yapısı
class ProductApiService {
  /// Belirli bir buzdolabının içindeki ürünleri getirir.
  Future<List<ProductItem>> getMyInventory(String fridgeId) async {
    final response = await apiClient.get('/private-fridges/$fridgeId/items');
    final data = response.data;
    final List<dynamic> itemsJson =
        (data is Map && data['items'] is List) ? data['items'] as List : [];
    return itemsJson
        .map((json) => ProductItem.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  /// Buzdolabına yeni ürün ekler.
  Future<void> addItemToInventory(
    String fridgeId, {
    required String name,
    required int quantity,
    String? expiryDate,
    String? category,
    String? unit,
    String? imageUrl,
  }) async {
    await apiClient.post(
      '/private-fridges/$fridgeId/items',
      data: {
        'name': name,
        'quantity': quantity,
        if (expiryDate != null) 'expiryDate': expiryDate,
        if (category != null) 'category': category,
        if (unit != null) 'unit': unit,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
  }

  /// Bir ürünü public buzdolabına transfer eder.
  Future<Map<String, dynamic>> transferItemToFridge(
    int itemId,
    int targetFridgeId,
  ) async {
    final response = await apiClient.put(
      '/private-fridges/items/$itemId/transfer',
      data: {'targetFridgeId': targetFridgeId},
    );
    final data = response.data;
    if (data is Map && data['item'] is Map) {
      return Map<String, dynamic>.from(data['item'] as Map);
    }
    return Map<String, dynamic>.from(data as Map);
  }
}
