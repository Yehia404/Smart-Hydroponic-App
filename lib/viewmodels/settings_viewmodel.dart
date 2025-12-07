import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../data/models/threshold_config.dart';
import '../view/auth/login_screen.dart';
import '../view/settings/sensor_thresholds_screen.dart';
import '../view/settings/notification_settings_screen.dart';
import '../view/settings/automation_rules_screen.dart';
import '../view/settings/user_profile_screen.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  void openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
    );
  }

  void openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void openAutomationRules(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutomationRulesScreen()),
    );
  }

  void openSensorThresholds(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SensorThresholdsScreen()),
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      // Reset ThresholdConfig to defaults BEFORE logout
      // This prevents stale thresholds from triggering notifications
      ThresholdConfig.instance.resetToDefaults();
      debugPrint('🔄 LOGOUT: Reset thresholds to defaults');

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
