import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/services/auth_service.dart';

enum SplashDestination { login, dashboard }

class SplashScreenViewModel extends ChangeNotifier {
  final AuthService _authService;

  SplashScreenViewModel(this._authService);

  /// Handles the entire startup sequence
  /// Returns the destination so the View knows where to navigate
  Future<SplashDestination> initializeApp() async {
    // 1. Wait for Animation (Simulated loading)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Request Permissions (Logic moved here)
    await _requestPermissions();

    // 3. Check Authentication
    final user = _authService.currentUser;

    if (user != null) {
      return SplashDestination.dashboard;
    } else {
      return SplashDestination.login;
    }
  }

  Future<void> _requestPermissions() async {
    // We can ask for permissions without context!
    PermissionStatus status = await Permission.notification.request();

    if (status.isDenied) {
      debugPrint("User denied notifications");
      // You could set an error state here if you wanted to show a message
    }
  }
}
