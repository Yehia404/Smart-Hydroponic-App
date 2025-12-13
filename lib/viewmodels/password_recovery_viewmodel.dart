import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';

enum RecoveryState {
  Initial, // Show text field
  Loading, // Show spinner
  Success, // Show "Check your email" message
  Error, // Show error message
}

class PasswordRecoveryViewModel extends ChangeNotifier {
  final AuthService _authService;
  PasswordRecoveryViewModel(this._authService);

  RecoveryState _state = RecoveryState.Initial;
  String? _errorMessage;

  // Getters for the UI
  RecoveryState get state => _state;
  String? get errorMessage => _errorMessage;

  /// Sends the password reset link.
  Future<void> sendResetLink(String email) async {
    _setState(RecoveryState.Loading);
    _errorMessage = null;

    // 1. Validation
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = "Please enter a valid email address.";
      _setState(RecoveryState.Error);
      return;
    }

    // 2. Call Firebase Service
    try {
      await _authService.sendPasswordResetEmail(email);
      // Success!
      _setState(RecoveryState.Success);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = "No user found with that email address.";
      } else {
        _errorMessage = "An error occurred. Please try again.";
      }
      _setState(RecoveryState.Error);
    } catch (e) {
      _errorMessage = "An unexpected error occurred.";
      _setState(RecoveryState.Error);
    }
  }

  // Helper to update state and notify UI
  void _setState(RecoveryState newState) {
    _state = newState;
    notifyListeners();
  }
}
