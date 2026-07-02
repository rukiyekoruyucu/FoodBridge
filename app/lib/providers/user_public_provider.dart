import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/core/api_client.dart';

/// /users/:id/public üzerinden chat UI için minimum user bilgisini çeker.
/// Response tolerant:
/// - { user: {...} }
/// - { ...userFields }
class UserPublicLite {
  final int id;
  final String? fullName;
  final String? avatarUrl;

  const UserPublicLite({
    required this.id,
    this.fullName,
    this.avatarUrl,
  });

  String get displayName {
    final n = (fullName ?? '').trim();
    return n.isNotEmpty ? n : 'Kullanıcı';
  }
}

final userPublicProvider = FutureProvider.autoDispose.family<UserPublicLite, int>(
  (ref, userId) async {
    final res = await apiClient.get('/users/$userId/public');
    final data = res.data;

    Map<String, dynamic> u = {'id': userId};

    if (data is Map) {
      final maybeUser = data['user'];
      if (maybeUser is Map) {
        u = Map<String, dynamic>.from(maybeUser);
      } else {
        u = Map<String, dynamic>.from(data);
      }
    }

    final id = (u['id'] is int) ? (u['id'] as int) : userId;
    final fullName = (u['full_name'] ?? u['fullName'] ?? u['name'])?.toString();
    final avatarUrl = (u['avatar_url'] ?? u['avatarUrl'])?.toString();

    return UserPublicLite(id: id, fullName: fullName, avatarUrl: avatarUrl);
  },
);
