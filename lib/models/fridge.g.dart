// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fridge _$FridgeFromJson(Map<String, dynamic> json) => Fridge(
  fridgeId: json['fridge_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  distance: (json['distance'] as num).toDouble(),
  itemCount: (json['item_count'] as num).toInt(),
);

Map<String, dynamic> _$FridgeToJson(Fridge instance) => <String, dynamic>{
  'fridge_id': instance.fridgeId,
  'name': instance.name,
  'description': instance.description,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'distance': instance.distance,
  'item_count': instance.itemCount,
};
