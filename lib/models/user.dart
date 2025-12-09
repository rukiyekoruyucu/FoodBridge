import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';


@JsonSerializable()
class User {

  @JsonKey(name: 'user_id')
  final String userId;

  final String email;
  final String username;
  final String role;

  @JsonKey(name: 'kindness_points', defaultValue: 0)
  final int kindnessPoints;

  User({
    required this.userId,
    required this.email,
    required this.username,
    required this.role,
    this.kindnessPoints = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}