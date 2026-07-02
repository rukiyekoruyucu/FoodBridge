import 'package:json_annotation/json_annotation.dart';

part 'product_item.g.dart';

@JsonSerializable()
class ProductItem {
  // ✅ backend int döndürüyor — String değil
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'fridge_id')
  final int? fridgeId;

  @JsonKey(name: 'donor_user_id')
  final int? donorUserId;

  final String name;

  @JsonKey(defaultValue: 1)
  final int quantity;

  @JsonKey(name: 'expiry_date')
  final String? expiryDate;

  final String? category;
  final String? unit;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  // ✅ Yazım hatası düzeltildi: 'is_avaible' → 'status'
  @JsonKey(name: 'status', defaultValue: 'AVAILABLE')
  final String status;

  bool get isAvailable => status == 'AVAILABLE';

  ProductItem({
    required this.id,
    this.fridgeId,
    this.donorUserId,
    required this.name,
    this.quantity = 1,
    this.expiryDate,
    this.category,
    this.unit,
    this.imageUrl,
    this.status = 'AVAILABLE',
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) =>
      _$ProductItemFromJson(json);
  Map<String, dynamic> toJson() => _$ProductItemToJson(this);
}