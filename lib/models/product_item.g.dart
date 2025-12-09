// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductItem _$ProductItemFromJson(Map<String, dynamic> json) => ProductItem(
  itemId: json['item_id'] as String,
  fridgeId: json['fridge_id'] as String?,
  donorUserId: json['donor_user_id'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  expiryDate: json['expiry_date'] as String,
  category: json['category'] as String,
  isAvailable: json['is_avaible'] as bool,
);

Map<String, dynamic> _$ProductItemToJson(ProductItem instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'fridge_id': instance.fridgeId,
      'donor_user_id': instance.donorUserId,
      'name': instance.name,
      'quantity': instance.quantity,
      'expiry_date': instance.expiryDate,
      'category': instance.category,
      'is_avaible': instance.isAvailable,
    };
