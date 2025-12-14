import 'package:flutter/material.dart';

class DashboardViewModel extends ChangeNotifier {
  void navigateToAlerts(BuildContext context) {
    // Navigation logic moved to ViewModel
    // You can add analytics tracking or other logic here
  }

  void navigateToSettings(BuildContext context) {
    // Navigation logic moved to ViewModel
  }

  void logout(BuildContext context) {
    // TODO: Call AuthService to logout
    // Clear user session, reset state, etc.
  }
}
