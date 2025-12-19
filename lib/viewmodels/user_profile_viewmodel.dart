import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/auth_service.dart';
import '../view/auth/login_screen.dart';

class UserProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  String _userName = 'Loading...';
  String _userEmail = '';
  bool _isLoading = true;

  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userId => _authService.currentUser?.uid ?? 'Unknown ID';
  bool get isLoading => _isLoading;

  UserProfileViewModel() {
    _loadUserProfile();
  }

  /// Loads user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _authService.currentUser;
      if (user != null) {
        _userEmail = user.email ?? 'No email';

        // Fetch user profile from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          _userName = userDoc.data()?['name'] ?? 'Unknown User';
        } else {
          _userName = 'Unknown User';
        }
      } else {
        _userName = 'Unknown User';
        _userEmail = 'No email';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userName = 'Error loading name';
      _userEmail = _authService.currentUser?.email ?? 'Error loading email';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes user profile data
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  /// Updates user's display name in Firestore
  Future<bool> updateUserName(String newName) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName.trim()});

        _userName = newName.trim();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating user name: $e');
      return false;
    }
  }

  /// Changes user's password after verifying old password
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      final user = _authService.currentUser;
      if (user == null || user.email == null) {
        return 'No user logged in';
      }

      // Re-authenticate user with old password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        return 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        return 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        return 'Please log out and log in again before changing password';
      } else {
        return e.message ?? 'Failed to change password: ${e.code}';
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      return 'An error occurred while changing password';
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }
}