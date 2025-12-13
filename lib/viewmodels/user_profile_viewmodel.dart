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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }
}
