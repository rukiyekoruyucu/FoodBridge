import 'package:foodbridge/models/product_item.dart';

class FridgeProductsState {
  final List<ProductItem> products;
  final bool isLoading;
  final String? error;

  FridgeProductsState({
    this.products = const[],
    this.isLoading = false,
    this.error,
  });

  FridgeProductsState copyWith({
    List<ProductItem>? products,
    bool? isLoading,
    String? error,
  }) {
    return FridgeProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}