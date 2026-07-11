import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/screens/login_screen.dart';

// AuthWrapper — sadece login yönlendirmesi için kullanılır.
// Ana navigasyon GoRouter + HomeShell üzerinden yönetilir (router.dart).
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Authenticated: GoRouter redirect handles navigation to /home/feed
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
