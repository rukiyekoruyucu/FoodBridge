import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/services/product_api_service.dart';
import 'inventory_state.dart';

final productApiServiceProvider = StateProvider<ProductApiService>(
  (ref) => ProductApiService(),
);

class InventoryNotifier extends StateNotifier<InventoryState> {
  final ProductApiService _productApi;

  // ✅ Şu an aktif buzdolabı ID'si (private fridges listesinden seçilir)
  String? _activeFridgeId;

  InventoryNotifier(this._productApi) : super(InventoryState());

  void setActiveFridge(String fridgeId) {
    _activeFridgeId = fridgeId;
    loadInventory();
  }

  Future<void> loadInventory() async {
    final fridgeId = _activeFridgeId;
    if (fridgeId == null) {
      // Aktif buzdolabı yoksa boş liste göster
      state = state.copyWith(inventoryItems: [], isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _productApi.getMyInventory(fridgeId);
      state = state.copyWith(inventoryItems: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addItem({
    required String name,
    required int quantity,
    String? expiryDate,
    String? category,
    String? unit,
    String? imageUrl,
  }) async {
    final fridgeId = _activeFridgeId;
    if (fridgeId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _productApi.addItemToInventory(
        fridgeId,
        name: name,
        quantity: quantity,
        expiryDate: expiryDate,
        category: category,
        unit: unit,
        imageUrl: imageUrl,
      );
      // Listeyi yenile
      await loadInventory();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // ✅ int parametreler (ProductItem.id = int)
  Future<void> transferToFridge(int itemId, int targetFridgeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _productApi.transferItemToFridge(itemId, targetFridgeId);
      final updatedList =
          state.inventoryItems.where((item) => item.id != itemId).toList();
      state = state.copyWith(inventoryItems: updatedList, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      return InventoryNotifier(ref.watch(productApiServiceProvider));
    });
