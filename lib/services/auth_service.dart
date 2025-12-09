import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

Future<String?> getIdToken() async {
  final user = _auth.currentUser;

  return user != null ? await user.getIdToken() : null;
}

Future<UserCredential> register(String email, String password) async {
  return await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
}

Future<void> signOut() async {
  await _auth.signOut();  
  }

}