import 'package:foodbridge/models/product_item.dart';

class InventoryState {
  final List<ProductItem> inventoryItems;
  final bool isLoading;
  final String? error;

  InventoryState({
    this.inventoryItems = const [],
    this.isLoading = false,
    this.error,
  });

  InventoryState copyWith({
    List<ProductItem>? inventoryItems,
    bool? isLoading,
    String? error,
  }) {
    return InventoryState(
      inventoryItems: inventoryItems ?? this.inventoryItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}