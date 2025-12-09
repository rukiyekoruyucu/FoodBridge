import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/legacy.dart';
import 'package:foodbridge/models/user.dart';
import 'package:foodbridge/services/auth_service.dart';
import 'package:foodbridge/services/auth_api_service.dart';
import 'package:foodbridge/providers/auth_state.dart';


class AuthNotifier extends StateNotifier<AppAuthState>{
  final AuthApiService _apiService;

  AuthNotifier(this._apiService) : super(AppAuthState()){
    checkInitialAuthStatus();
  }

  Future<void> checkInitialAuthStatus() async {
    try{
    if(firebase_auth.FirebaseAuth.instance.currentUser != null){
      await fetchRoleAndUserData();
    } else{
      state = AppAuthState(isAuthenticated: false, isLoading: false);
    }
    } catch (e){
      state = AppAuthState(isAuthenticated: false, isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchRoleAndUserData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final role = await _apiService.fetchUserRole();
      if (role != null){
        final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
        final userModel = User(
          userId: currentUser!.uid,
          email: currentUser.email!,
          username: currentUser.displayName ?? 'User', 
          role: role,
          kindnessPoints: 0,
        );

        state = AppAuthState(
          user: userModel,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        await signOut();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false, isAuthenticated: false);
  }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.loginUser(email: email, password: password);
      await fetchRoleAndUserData();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signOut() async {
    await AuthService().signOut();
    state = AppAuthState(isAuthenticated: false);
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userModel = await _apiService.registerUser(
        email: email,
        password: password,
        username: username,
        role: role,
      );

      state = state.copyWith(
        user: userModel,
        isAuthenticated: true,
        isLoading: false,
        error: null
        );

    } catch (e) {
      state = state.copyWith(error: e.toString().replaceFirst('Exception', ''), isLoading: false);
    }
  }


}
final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(AuthApiService());
});