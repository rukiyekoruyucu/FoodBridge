// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  firebaseUid: json['firebase_uid'] as String,
  fullName: json['full_name'] as String?,
  username: json['username'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  bio: json['bio'] as String?,
  email: json['email'] as String,
  role: json['role'] as String,
  kindnessPoints: (json['kindness_points'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'firebase_uid': instance.firebaseUid,
  'full_name': instance.fullName,
  'username': instance.username,
  'email': instance.email,
  'role': instance.role,
  'kindness_points': instance.kindnessPoints,
  'avatar_url': instance.avatarUrl,
  'bio': instance.bio,
};
