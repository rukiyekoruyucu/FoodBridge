import 'package:foodbridge/utils/api_client.dart';
import 'package:foodbridge/models/product_item.dart';

class ProductApiService {

  Future<List<ProductItem>> getMyInventory() async {

    final response = await apiClient.get('/private-fridge/items');
    final List<dynamic> itemsJson = response.data['items'];
    return itemsJson.map((json) => ProductItem.fromJson(json)).toList();
  }

  Future<ProductItem> addItemToInventory({
    required String name,
    required int quantity,
    required String expiryDate,
    required String category
  }) async {

    final response = await apiClient.post('/private-fridge/items', data: {
      'name': name,
      'quantity': quantity,
      'expiryDate': expiryDate,
      'category': category,
    });

    return ProductItem.fromJson(response.data['item']);
  }

  Future<ProductItem> transferItemToFridge(String itemId, String targetFridgeId) async {
    final response = await apiClient.put('/private-fridge/items/$itemId/transfer', data: {
      'targetFridgeId': targetFridgeId,
    });
    return ProductItem.fromJson(response.data['item']);
  }
}