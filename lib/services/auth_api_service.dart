import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:foodbridge/utils/api_client.dart';
import 'package:foodbridge/services/auth_service.dart';
import 'package:foodbridge/models/user.dart';

class AuthApiService {
  
  Future<User> registerUser({
    required String email,
    required String password,
    required String username, 
    required String role,
  }) async {
    try {

      await AuthService().register(email, password);

      final response = await apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'username': username,
        'role': role,
      });

      return User.fromJson(response.data);

    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } on DioException catch (e) {
      final serverMessage = e.response?.data['error'] ?? e.response?.data['message']?? 'Registration failed';
      throw Exception(serverMessage);
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try{
      await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
    } on firebase_auth.FirebaseAuthException catch (e){
      throw Exception('Login failed: ${e.message ?? 'Wrong credentials'}');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'A server error occurred during login');
    }
  }
    
    Future<String?> fetchUserRole() async {
    try {
      final response = await apiClient.get('/auth/user-role');
      return response.data['role'];
    } on DioException catch (e) {
      if(e.response?.statusCode == 401) {
        AuthService().signOut();
        return null;
      }
      throw Exception('Failed to fetch user role');
    }

    }
  }
