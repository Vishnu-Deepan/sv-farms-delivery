// login_logic.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../services/shared_preferences_helper.dart';

class LoginLogic {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to log in the user
  Future<void> loginUser({
    required String email,
    required String password,
    required Function onSuccess,
    required Function(String) onFailure,
  }) async {
    try {
      // Validate email and password
      if (email.isEmpty || password.isEmpty) {
        onFailure("Please enter email and password.");
        return;
      }

      // Email validation regex
      final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");
      if (!emailRegex.hasMatch(email)) {
        onFailure("Please enter a valid email address.");
        return;
      }

      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Save user session
        await SharedPreferencesHelper.saveUserSession(
          user.uid,
          user.email!,
        );
        onSuccess();
      }
    } catch (e) {
      onFailure("Login failed. Error: $e");
    }
  }

  // Auto login method for testing purposes (can be commented out in production)
  Future<void> autoLogin({
    required String testEmail,
    required String testPassword,
    required Function onSuccess,
    required Function(String) onFailure,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      final user = userCredential.user;
      if (user != null) {
        // Save user session
        await SharedPreferencesHelper.saveUserSession(
          user.uid,
          user.email!
        );
        onSuccess();
      }
    } catch (e) {
      onFailure("Login failed. Error: $e");
    }
  }
}
