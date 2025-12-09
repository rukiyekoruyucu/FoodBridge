import 'package:json_annotation/json_annotation.dart';

part 'fridge.g.dart';

@JsonSerializable()
class Fridge {
  @JsonKey(name: 'fridge_id')
  final String fridgeId;

  final String name;
  final String description;
  final double latitude;
  final double longitude;

  final double distance;

  @JsonKey(name: 'item_count')
  final int itemCount;

  Fridge({
    required this.fridgeId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.itemCount,
  });
  factory Fridge.fromJson(Map<String, dynamic> json) => _$FridgeFromJson(json);
  Map<String, dynamic> toJson() => _$FridgeToJson(this);
}