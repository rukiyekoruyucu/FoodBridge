import 'package:foodbridge/utils/api_client.dart';
import 'package:foodbridge/models/fridge.dart';
import 'package:foodbridge/models/product_item.dart';

class FridgeApiService {

  Future<List<Fridge>> fetchFridgesNearMe(double lat, double lon) async {
    try{
      final response = await apiClient.get('/fridges', queryParameters: {
        'lat': lat,
        'lon': lon,
      });

      final List<dynamic> fridgesJson = response.data['fridges'] ?? [];

      return fridgesJson.map((json) => Fridge.fromJson(json)).toList();

    }catch (e) {
      rethrow;
    }
  }

  Future<List<ProductItem>> fetchFridgeProducts(String fridgeId) async {
    try{
      final response = await apiClient.get('/fridges/$fridgeId/products');

      final List<dynamic> productsJson = response.data['products'] ?? [];

      return productsJson.map((json) => ProductItem.fromJson(json)).toList();

    }catch (e) {
      rethrow;
    }
  }

}