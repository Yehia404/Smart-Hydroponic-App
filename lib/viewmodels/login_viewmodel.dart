import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  LoginViewModel(this._authService);

  bool _isLoading = false;
  String? _errorMessage;

  // Getters for the UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    // 1. Data Validation
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = "Please enter a valid email address.";
      _setLoading(false);
      return false;
    }
    if (password.isEmpty) {
      _errorMessage = "Please enter your password.";
      _setLoading(false);
      return false;
    }

    // 2. Call Firebase Auth Service
    try {
      User? user = await _authService.login(email, password);

      _setLoading(false);

      if (user != null) {
        return true;
      } else {
        _errorMessage = "Login failed. Please check your credentials.";
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _errorMessage = "An error occurred: $e";
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
