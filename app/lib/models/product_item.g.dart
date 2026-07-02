// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductItem _$ProductItemFromJson(Map<String, dynamic> json) => ProductItem(
  id: (json['id'] as num).toInt(),
  fridgeId: (json['fridge_id'] as num?)?.toInt(),
  donorUserId: (json['donor_user_id'] as num?)?.toInt(),
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  expiryDate: json['expiry_date'] as String?,
  category: json['category'] as String?,
  unit: json['unit'] as String?,
  imageUrl: json['image_url'] as String?,
  status: json['status'] as String? ?? 'AVAILABLE',
);

Map<String, dynamic> _$ProductItemToJson(ProductItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fridge_id': instance.fridgeId,
      'donor_user_id': instance.donorUserId,
      'name': instance.name,
      'quantity': instance.quantity,
      'expiry_date': instance.expiryDate,
      'category': instance.category,
      'unit': instance.unit,
      'image_url': instance.imageUrl,
      'status': instance.status,
    };
