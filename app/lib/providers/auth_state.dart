import 'package:foodbridge/models/user.dart';

class AppAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  const AppAuthState({
    required this.isAuthenticated,
    required this.isLoading,
    required this.user,
    required this.error,
  });

  factory AppAuthState.initial() {
    return const AppAuthState(
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: null,
    );
  }

  AppAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
    bool clearUser = false,
  }) {
    return AppAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: error,
    );
  }
}
