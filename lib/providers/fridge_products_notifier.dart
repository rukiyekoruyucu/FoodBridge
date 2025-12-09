import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/services/fridge_api_service.dart';
import 'fridge_products_state.dart';

final fridgeApiServiceProvider = Provider((ref) => FridgeApiService()); 

final fridgeProductsProvider = StateNotifierProvider.autoDispose.family<
    FridgeProductsNotifier, FridgeProductsState, String>(
  (ref, fridgeId) {

    return FridgeProductsNotifier(
      fridgeId,
      ref.watch(fridgeApiServiceProvider),
    );
    
  });

class FridgeProductsNotifier extends StateNotifier<FridgeProductsState> {
  final String _fridgeId;
  final FridgeApiService _apiService;

  FridgeProductsNotifier(this._fridgeId, this._apiService)
      : super(FridgeProductsState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {  
      final products = await _apiService.fetchFridgeProducts(_fridgeId);
      state = state.copyWith(
        products: products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
