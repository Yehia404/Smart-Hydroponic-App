import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Get the instance of Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ADD THIS GETTER:
  User? get currentUser => _auth.currentUser;
  // --- Singleton Setup ---
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  /// Provides a stream to listen to authentication changes.
  ///
  /// Use this to check if a user is logged in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Tries to log in a user with email and password.
  /// Returns a [User] object on success, or null on failure.
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // You can handle specific errors here in the ViewModel
      print('Login Error: ${e.message}');
      return null;
    }
  }

  /// Tries to register a new user with email, password, and creates a Firestore profile.
  /// Returns a [User] object on success, or null on failure.
  Future<User?> register(
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      print('🔵 AUTH SERVICE: Starting registration for email: $email');
      print('🔵 AUTH SERVICE: Full name received: $fullName');

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      print('✅ AUTH SERVICE: Firebase Auth user created successfully');

      // Create Firestore user profile if name is provided
      if (fullName != null &&
          fullName.isNotEmpty &&
          userCredential.user != null) {
        print('🔵 AUTH SERVICE: Creating Firestore user profile...');

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'name': fullName.trim(),
                'email': email.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });
          print('✅ AUTH SERVICE: User profile created in Firestore');
        } catch (e) {
          print('⚠️ AUTH SERVICE: Failed to create Firestore profile: $e');
          // Don't fail registration if Firestore write fails
        }
      } else {
        print('⚠️ AUTH SERVICE: Full name not provided');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Registration Error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected Registration Error: $e');
      return null;
    }
  }

  /// Sends a password reset email to the user.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      // Re-throw the exception so the ViewModel can catch it
      // and show a specific error (e.g., "user-not-found")
      rethrow;
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }
}
