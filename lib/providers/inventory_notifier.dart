import 'package:flutter_riverpod/legacy.dart';

import 'package:foodbridge/services/product_api_service.dart';
import 'inventory_state.dart';

final productApiServiceProvider = StateProvider<ProductApiService>((ref)=> ProductApiService());

class InventoryNotifier extends StateNotifier<InventoryState>{
  final ProductApiService _productApi;
  
  InventoryNotifier(this._productApi) : super(InventoryState());

  Future<void> loadInventory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _productApi.getMyInventory();
      state = state.copyWith(
        inventoryItems: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }

  }
  Future<void> addItem({
    required String name,
    required int quantity,
    required String expiryDate,
    required String category
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newItem = await _productApi.addItemToInventory(
        name: name,
        quantity: quantity,
        expiryDate: expiryDate,
        category: category,
      );
      
      state = state.copyWith(
        inventoryItems: [...state.inventoryItems, newItem],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> transferToFridge(String itemId, String fridgeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try{
      await _productApi.transferItemToFridge(itemId, fridgeId);
      final updatedList = state.inventoryItems.where((item) => item.itemId != itemId).toList();
      state = state.copyWith(
        inventoryItems: updatedList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }


  }
}
final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier(ref.watch(productApiServiceProvider));
});