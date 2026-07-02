// lib/models/user.dart

import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;

  @JsonKey(name: 'firebase_uid')
  final String firebaseUid;

  // 🔥 Düzeltme: Backend'den NULL gelebilir (veritabanı NULL'a izin veriyorsa)
  @JsonKey(name: 'full_name')
  final String? fullName;

  // 🔥 Düzeltme: Backend'den NULL gelebilir
  final String? username;

  final String email;
  final String
  role; // Rolün NULL olması ihtimali düşük, ama gerekirse bu da String? yapılabilir.

  @JsonKey(name: 'kindness_points', defaultValue: 0)
  final int kindnessPoints;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'bio')
  final String? bio;

  User({
    required this.id,
    required this.firebaseUid,
    this.fullName, // Artık 'required' değil
    this.username, // Artık 'required' değil
    this.avatarUrl,
    this.bio,
    required this.email,
    required this.role,
    this.kindnessPoints = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
