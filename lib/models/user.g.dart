// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  userId: json['user_id'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  role: json['role'] as String,
  kindnessPoints: (json['kindness_points'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'user_id': instance.userId,
  'email': instance.email,
  'username': instance.username,
  'role': instance.role,
  'kindness_points': instance.kindnessPoints,
};
