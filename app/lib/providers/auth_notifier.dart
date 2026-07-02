import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:foodbridge/providers/auth_state.dart';
import 'package:foodbridge/services/auth_api_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(AuthApiService());
});

class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthApiService _api;
  StreamSubscription<fb.User?>? _sub;

  bool _isRegistering = false;
  int _seq = 0;

  AuthNotifier(this._api) : super(AppAuthState.initial()) {
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    _sub = fb.FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
      final mySeq = ++_seq;

      // logout
      if (fbUser == null) {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          user: null,
          error: null,
        );
        return;
      }

      // register esnasında /me çağırma
      if (_isRegistering) return;

      state = state.copyWith(isLoading: true, error: null);

      try {
        final String? token = await fbUser.getIdToken(true);

        if (token == null || token.isEmpty) {
          throw Exception('Firebase token alınamadı');
        }

        final me = await _api.meWithToken(token);

        if (mySeq != _seq) return;

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: me,
          error: null,
        );
      } catch (e) {
        if (mySeq != _seq) return;

        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          user: null,
          error: e.toString(),
        );
      }
    });
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // authStateChanges listener /me çağırır
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String username,
    required String role,
    String? companyName,
    String? location,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    _isRegistering = true;

    try {
      final cred = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await _api.register(
        firebaseUid: cred.user!.uid,
        fullName: fullName,
        email: email,
        username: username,
        role: role,
        companyName: companyName,
        location: location,
      );

      _isRegistering = false;

      final String? token = await cred.user!.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw Exception('Firebase token alınamadı');
      }

      final me = await _api.meWithToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: me,
        error: null,
      );
    } catch (e) {
      _isRegistering = false;
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Profile ekranından “yenile” basınca çağır
  Future<void> refreshMe() async {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    final mySeq = ++_seq;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final String? token = await fbUser.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw Exception('Firebase token alınamadı');
      }

      final me = await _api.meWithToken(token);

      if (mySeq != _seq) return;

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: me,
        error: null,
      );
    } catch (e) {
      if (mySeq != _seq) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await fb.FirebaseAuth.instance.signOut();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
