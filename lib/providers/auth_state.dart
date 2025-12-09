import 'package:foodbridge/models/user.dart';

class AppAuthState{
  final User? user;
  final bool isLoading;
  final String? error;

  final bool isAuthenticated;

  AppAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  }); 

  AppAuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }){
    return AppAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}