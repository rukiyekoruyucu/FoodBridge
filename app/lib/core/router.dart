// lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/screens/login_screen.dart';
import 'package:foodbridge/screens/register_screen.dart';
import 'package:foodbridge/screens/home_screen.dart';
import 'package:foodbridge/screens/map_screen.dart';
import 'package:foodbridge/screens/private_fridges_screen.dart';
import 'package:foodbridge/screens/profile_screen.dart';
import 'package:foodbridge/screens/chat_list_screen.dart';
import 'package:foodbridge/screens/chat_screen.dart';
import 'package:foodbridge/screens/private_fridge_detail_screen.dart';
import 'package:foodbridge/screens/public_profile_screen.dart';
import 'package:foodbridge/screens/notifications_screen.dart';
import 'package:foodbridge/screens/settings_screen.dart';
import 'package:foodbridge/screens/donation_requests_screen.dart';
import 'package:foodbridge/screens/inventory_screen.dart';
import 'package:foodbridge/widgets/home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: '/home/feed',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final onAuth = loc.startsWith('/login') || loc.startsWith('/register');
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/home/feed';
      return null;
    },
    routes: [
      // ── Auth screens ───────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main shell — StatefulShellRoute keeps per-branch nav state ─────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final auth = ref.read(authProvider);
          final role = auth.user?.role ?? 'PERSONAL';
          return HomeShell(navigationShell: navigationShell, userRole: role);
        },
        branches: [
          // Branch 0: Feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/feed',
                builder: (context, state) {
                  final auth = ref.read(authProvider);
                  final role = auth.user?.role ?? 'PERSONAL';
                  return HomeScreen(userRole: role, embedded: true);
                },
              ),
            ],
          ),
          // Branch 1: Fridges
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/fridges',
                builder: (context, state) {
                  final auth = ref.read(authProvider);
                  final role = auth.user?.role ?? 'PERSONAL';
                  return PrivateFridgesScreen(userRole: role);
                },
              ),
            ],
          ),
          // Branch 2: Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/map',
                builder: (context, state) {
                  final auth = ref.read(authProvider);
                  final role = auth.user?.role ?? 'PERSONAL';
                  return MapScreen(userRole: role, embedded: true);
                },
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/profile',
                builder: (context, state) => const ProfileScreen(embedded: true),
              ),
            ],
          ),
        ],
      ),

      // ── Chat ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) {
          final roomId =
              int.tryParse(state.pathParameters['roomId'] ?? '0') ?? 0;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            roomId: roomId,
            partnerName: extra?['partnerName'] as String? ?? '',
            partnerId: extra?['partnerId'] as int?,
            partnerAvatarUrl: extra?['partnerAvatarUrl'] as String?,
          );
        },
      ),

      // ── Fridge detail ──────────────────────────────────────────────────────
      GoRoute(
        path: '/fridge/:fridgeId',
        builder: (context, state) {
          final fridgeId = state.pathParameters['fridgeId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final auth = ref.read(authProvider);
          return PrivateFridgeDetailScreen(
            fridgeId: fridgeId,
            fridgeName: extra?['fridgeName'] as String? ?? 'Buzdolabı',
            userRole: auth.user?.role ?? 'PERSONAL',
          );
        },
      ),

      // ── Public profile ─────────────────────────────────────────────────────
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId =
              int.tryParse(state.pathParameters['userId'] ?? '0') ?? 0;
          final extra = state.extra as Map<String, dynamic>?;
          final auth = ref.read(authProvider);
          final role = auth.user?.role ?? 'PERSONAL';
          return PublicProfileScreen(
            userId: userId,
            displayName: extra?['displayName'] as String?,
            avatarUrl: extra?['avatarUrl'] as String?,
            canRequest: role == 'NEEDY',
          );
        },
      ),

      // ── Notifications ──────────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ── Settings ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Donation requests ──────────────────────────────────────────────────
      GoRoute(
        path: '/donations',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final itemId = extra?['itemId'] as int? ?? 0;
          return DonationRequestsScreen(itemId: itemId);
        },
      ),

      // ── Inventory ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const ProductAddScreen(),
      ),
    ],
  );
});

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (prev, next) => notifyListeners());
  }
}
