import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';

class RegistrationViewModel extends ChangeNotifier {
  final AuthService _authService;

  RegistrationViewModel(this._authService);

  bool _isLoading = false;
  String? _errorMessage;

  // Getters for the UI to listen to
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Attempts to register a new user
  Future<bool> register(
    String fullName,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _setLoading(true);
    _errorMessage = null;

    // 1. Data Validation (Requirement #4)
    if (fullName.isEmpty) {
      _errorMessage = "Please enter your full name.";
      _setLoading(false);
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = "Please enter a valid email.";
      _setLoading(false);
      return false;
    }
    if (password.length < 6) {
      _errorMessage = "Password must be at least 6 characters long.";
      _setLoading(false);
      return false;
    }
    if (password != confirmPassword) {
      _errorMessage = "Passwords do not match.";
      _setLoading(false);
      return false;
    }

    // 2. Call Firebase Auth Service
    try {
      print('🟢 VIEWMODEL: Calling register with fullName: $fullName');
      User? user = await _authService.register(
        email,
        password,
        fullName: fullName,
      );

      _setLoading(false);

      if (user != null) {
        // Success!
        print('✅ VIEWMODEL: Registration successful. User ID: ${user.uid}');
        print(
          '✅ VIEWMODEL: User profile created in Firestore with name: $fullName',
        );
        return true;
      } else {
        // This case is rare, but good to have
        _errorMessage = "Registration failed. Please try again.";
        return false;
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      if (e.code == 'email-already-in-use') {
        _errorMessage = "This email is already registered.";
      } else {
        _errorMessage = "An error occurred: ${e.message}";
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = "An unexpected error occurred.";
      debugPrint("Registration Error: $e");
      return false;
    }
  }

  // Helper to update state and notify UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
