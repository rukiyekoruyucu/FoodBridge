import 'package:json_annotation/json_annotation.dart';

part 'product_item.g.dart';

@JsonSerializable()
class ProductItem{
  @JsonKey(name: 'item_id')
  final String itemId;

  @JsonKey(name: 'fridge_id')
  final String? fridgeId;

  @JsonKey(name: 'donor_user_id')
  final String donorUserId;

  final String name;
  final int quantity;

  @JsonKey(name: 'expiry_date') 
  final String expiryDate;

  final String category;

  @JsonKey(name: 'is_avaible')
  final bool isAvailable;

  ProductItem({
    required this.itemId,
    this.fridgeId,
    required this.donorUserId,
    required this.name,
    required this.quantity,
    required this.expiryDate,
    required this.category,
    required this.isAvailable,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) => _$ProductItemFromJson(json);
  Map<String, dynamic> toJson() => _$ProductItemToJson(this);
}